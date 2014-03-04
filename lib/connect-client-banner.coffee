# ***RuleEvaluator*** is an internal class used to evalute individual *ConnectClientBanner* rules.
class RuleEvaluator

  # Evaluate the given request against the given rule.
  # Returns `true` if the request matches the rule, `false` otherwise.
  evaluate_rule:(rule,req)=>
    value = null
    if rule['attr']?
      value = req[rule['attr']]
    else if rule['header']?
      value = req.header(rule['header'])
    else if rule['predicate']?
      return rule['predicate'](req)
    else if (rule['AND'] or rule['ALL'])
      return @evaluate_and_of(rule['AND'] ? rule['ALL'],req)
    else if (rule['OR'] or rule['ANY'])
      return @evaluate_or_of(rule['OR'] ? rule['ANY'],req)
    else if (rule['NOT'] or rule['UNLESS'])
      return (not @evaluate_rule(rule['NOT'] ? rule['UNLESS'],req))
    else
      throw new Exception('Unrecognized rule format. Expected one of "attr", "header", "predicate", "AND", "ALL", "OR", "ANY", "NOT" or "UNLESS".')

    if rule['test']?
      return rule['test'](value)
    if rule['in']?
      for pattern in rule['in']
        if @predicate_matching(value,pattern)
          return true
      return false
    for verb in ['matching','matches','is','==','~=']
      if rule[verb]?
        return @predicate_matching(value,rule[verb])
    for verb in ['isnt','isn\'t','!=','<>']
      if rule[verb]?
        return @predicate_not_matching(value,rule[verb])
    for verb in ['>','>=','<=','<']
      if rule[verb]?
        return @predicate_compare(value,verb,rule[verb])
    throw new Exception('Unrecognized rule format. Expected one of "test", "matching", "matches", "is", "==", "~=", "isnt", "!=", "<>", "<", "<=", ">=" or "<".')

  #  A predicate function used to evaluate "<L> <OP> <R>" comparisons, such as `<= 5` or `!= 6`
  predicate_compare:(left,operator,right)=>
    switch operator
      when '<' then return (left < right)
      when '<=' then return (left <= right)
      when '=' then return (left == right)
      when '==' then return (left == right)
      when '==='then return (left is right)
      when '>=' then return (left >= right)
      when '>' then return (left > right)
      when '!=' then return (left != right)
      when '<>' then return (left != right)
      else
        throw new Error("Unrecognized operator #{operator}.")

  # A predicate function used to evaluate "matching" or "is" expressions (based on the pattern type).
  predicate_matching:(value,pattern)=>
    if pattern instanceof RegExp
      return pattern.test(value)
    else if typeof pattern is 'function'
      return pattern(value)
    else
      if value?
        if typeof pattern is Number
          value = parseFloat(value)
        else if typeof pattern is String
          value = value.toString()
      return (value is pattern)

  # The logical inverse of the `predicate_matching` function.
  predicate_not_matching:(value,pattern)=>
    (not @predicate_matching(value,pattern))

  # Ensure the given value is an array (by wrapping scalar values in a one-element array when needed).
  to_array:(value)=>
    if Array.isArray(value)
      return value
    else
      return [value]

  # Evaluate the given request against each rule in the given `rule_list`,
  # returning `false` if any individual rule does, `true` otherwise.
  evaluate_and_of:(rule_list, req)=>
    rule_list = @to_array(rule_list)
    for rule in rule_list
      unless @evaluate_rule(rule,req)
        return false
    return true

  # Evaluate the given request against each rule in the given `rule_list`,
  # returning `true` if any individual rule does, `false` otherwise.
  evaluate_or_of:(rule_list, req)=>
    rule_list = @to_array(rule_list)
    for rule in rule_list
      if @evaluate_rule(rule,req)
        return true
    return false


class ConnectClientBanner

  constructor:(options)->
    @configure(options)

  # Options:
  #  - `rules` - the list (array) of rules (defaults to `[]`)
  #  - `reset_interval` - the time (in milliseconds) between "resets" of the banned IP address list (defaults to 2 hours)
  #  - `ban_response` - the method to invoke when a request is being banned (defaults to sending a 403 status and then ending)
  #  - `evaluator` - a rule evaluator (defaults to `new RuleEvaluator()`); you probably don't need to override this.
  configure:(options)=>
    if options.evaluator?
      @rule_evaluator = options.evaluator
    @rule_evaluator ?= new RuleEvaluator()

    if options.rules?
      @rules = options.rules
    @rules ?= []

    if options.reset_interval?
      @reset_interval = options.reset_interval
    @reset_interval ?= 2*60*60*1000

    if options.ban_response?
      @ban_response = options.ban_response
    @ban_response ?= (req,res,next)=>
      res.status(403)
      res.end()

  # Returns `true` if the given request is banned under our current rule set.
  request_is_banned:(req)=>
    for rule in @rules
      if @rule_evaluator.evaluate_rule(rule,req)
        return true
    return false

  # The list of currently banned IP addresss.
  banned_ips: []
  # The timestamp (in milliseconds since the epoch) at which we last cleared the `banned_ips` list.
  last_reset: Date.now()
  # The number of blocked requests since this instance was created.
  total_blocked: 0
  # The number of blocked requests since the last reset.
  recently_blocked: 0
  # The number of not-blocked requests since this instance was created.
  total_allowed: 0
  # The number of not-blocked requests since the last reset.
  recently_allowed: 0

  # If the `reset_interval` has passed, clear the banned IP list amd return true.
  # Otherwise do nothing and return false.
  # Pass a single argument `true` to force a reset, no matter how long it has been since the last one.
  maybe_reset:(force=false)=>
    if force or ((@reset_interval > 0) and ((Date.now()-@last_reset) > @reset_interval))
      @banned_ips = []
      @last_reset = Date.now()
      @recently_blocked = 0
      @recently_allowed = 0
      return true
    else
      return false

  # Returns `true` if the given IP address is currently in the banned list.
  banned_ip:(client_ip)=>client_ip? and (client_ip in @banned_ips)

  # Determine the client IP address from the request.
  get_ip:(req)=>if req?.ips?[0]? then req.ips[0] else req?.ip

  # Add the given client IP address to the banned list.
  ban_ip:(client_ip)=>
    if client_ip?
      @banned_ips.push(client_ip)

  # Send the banned response (logging the request as needed).
  send_banned_response:(req,res,next)=>
    @total_blocked++
    @recently_blocked++
    @ban_response(req,res,next)

  # The middleware "handle" function.
  handle:(req,res,next)=>
    client_ip = @get_ip(req)
    if @banned_ip(client_ip)
      @_send_banned_response(req,res,next)
    else if @request_is_banned(req)
      @ban_ip(client_ip)
      @_send_banned_response(req,res,next)
    else
      next()
      @total_allowed++
      @recently_allowed++

  # Add this middleware to the given express app.
  add_middleware:(express_app)=>
    express_app.use @handle

  # Return a JSON data structure describing the banned list and other collected statistics.
  get_ban_data:()=>{
    banned:@banned_ips
    since:@last_reset
    blocked: {
      total: @total_blocked
      recent: @recently_blocked
    }
    allowed: {
      total: @total_allowed
      recent: @recently_allowed
    }
  }

exports = exports ? this
exports.ConnectClientBanner = ConnectClientBanner
