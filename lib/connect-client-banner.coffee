fs      = require 'fs'
path    = require 'path'
HOMEDIR = path.join(__dirname,'..')
LIB_COV = path.join(HOMEDIR,'lib-cov')
LIB_DIR = if fs.existsSync(LIB_COV) then LIB_COV else path.join(HOMEDIR,'lib')


# rule structure
# { attr: "path", matching:/regexp/ }
# { attr: "path", matching:"String" }
# { attr: "path", is:"String" }
# { attr: "path", is:Number }
# { attr: "path", is:Object }
# { attr: "path", isnt:"String" }
# { attr: "path", isnt:Number }
# { attr: "path", isnt:Object }
# { attr: "foo",  matching:function(req) }
# { attr: "foo",  ">":N }
# { attr: "foo",  ">=":N }
# { attr: "foo",  "<":N }
# { attr: "foo",  "<=":N }
# { attr: "foo",  "<=":N }
# { attr: "foo",  "==":N }
# { attr: "foo",  "!=":N }
# { attr: "foo",  "<>":N }
# { header: }
# { NOT: <rule> }
# { NOT: [ <rule>,... ] }
# { UNLESS: <rule> }
# { UNLESS: [ <rule>,... ] }
# { AND: [ <rule>,... ] }
# { OR: [ <rule>,... ] }
# { ALL: [ <rule>,... ] }
# { ANY: [ <rule>,... ] }
# { predicate: function(req) }


class RuleEvaluator

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

  predicate_not_matching:(value,pattern)=>(not @predicate_matching(value,pattern))

  to_array:(value)=>
    if Array.isArray(value)
      return value
    else
      return [value]

  evaluate_and_of:(rule_list, req)=>
    rule_list = @to_array(rule_list)
    for rule in rule_list
      unless @evaluate_rule(rule,req)
        return false
    return true

  evaluate_or_of:(rule_list, req)=>
    rule_list = @to_array(rule_list)
    for rule in rule_list
      if @evaluate_rule(rule,req)
        return true
    return false

DEFAULT_RULES = [
  { attr:'path', matches:/(\.|_)((aspx?)|(cfml?)|(cgi)|(php[0-9]?)|(do)|(jspa?)|(log)|(out)|(git[^\.]*)|(conf(ig)?)|(types)|(pl)|([a-z]+htm?l?)|(mspx))$/i }
  { attr:'path', matches:/[\&\|;`"'<>()%\$~\^\=: \+]/i }
  { attr:'path', matches:/admin/i }
  { attr:'path', matches:/cgi-bin/i }
  { attr:'path', matches:/login\/?$/i }
  { attr:'path', matches:/p\/m\/a/i }
  { attr:'path', matches:/php/i }
  { attr:'path', matches:/servlet\/?$/i }
  { attr:'path', matches:/w00t/i }
  { attr:'path', matches:/^\/wp/i }
  { attr:'path', matches:/--/ }
  { attr:'path', matches:/drop( |(%20)|\+)/i }
  { attr:'path', matches:/( |(%20)|\+)and( |(%20)|\+)/i }
  { attr:'path', matches:/( |(%20)|\+)or( |(%20)|\+)/i }
  { attr:'path', matches:/\.\./ }
  { attr:'path', matches:/\/((img)|(js)|(css)|(figure))\/?$/ }
  { attr:'path', matches:/\/\./ }
  { attr:'path', matches:/\/\// }
  { attr:'path', matches:/^\/?((my)|(web))?((sql)|(db))/i }
  { attr:'path', matches:/^\/?config/ }
  { attr:'path', matches:/^\/?manager\//i }
  { attr:'path', matches:/^\/?pma/i }
  { attr:'path', matches:/^\/?user\//i }
  { attr:'path', matches:/^\/a$/ }
  { attr:'path', matches:/^\/muie/i }
  { attr:'path', matches:/^\/user/i }
  { attr:'path', matches:/^\/x.txt/i }
  { header:'user-agent', matches:/panscient/ }
  { header:'user-agent', matches:/Indy Library/i }
  { header:'user-agent', matches:/ZmEu/i }
  { header:'user-agent', matches:/Morfeus Fucking Scanner/i }
  { header:'user-agent', matches:/Morfeus Fucking Scanner/i }
  { AND: [
    { attr:'path', is:'/how-to-umlaut' }
    { OR: [
      { header:'referer',in: [
        'http://buy-tramadolonline.org/'
        'http://ganja-seeds.net/'
        'http://pornoforadult.com/'
        'http://pornogig.com/'
        'http://sexmsk.nl/'
        'http://shiksabd.com/'
        'http://stop-drugs.net/'
        'http://xn--l1aengat.xn--p1ai/'
        'https://itunes.apple.com/us/app/cookies!-i-need-more-cookies!/id723364834'
      ] }
      { header:'referer',matches:/\.ru\/$/ }
    ] }
  ] }
]


class ConnectClientBanner
  constructor:()->
    @rule_evaluator = new RuleEvaluator()
    @rules = DEFAULT_RULES

  request_is_banned:(req)=>
    for rule in @rules
      if @rule_evaluator.evaluate_rule(rule,req)
        return true
    return false

  banned_ips: []
  last_reset: Date.now()
  millis_between_resets: 2*60*60*1000 # two hours
  total_blocked: 0
  recently_blocked: 0
  total_allowed: 0
  recently_allowed: 0

  maybe_reset:(force=false)=>
    if force or ((@millis_between_resets > 0) and ((Date.now()-@last_reset) > @millis_between_resets))
      @banned_ips = []
      @last_reset = Date.now()
      @recently_blocked = 0
      @recently_allowed = 0
      return true
    else
      return false

  banned_ip:(client_ip)=>client_ip? and (client_ip in @banned_ips)

  get_ip:(req)=>if req?.ips?[0]? then req.ips[0] else req?.ip

  ban_ip:(client_ip)=>
    if client_ip?
      @banned_ips.push(client_ip)

  _send_banned_response:(req,res,next)=>
    @total_blocked++
    @recently_blocked++
    @send_banned_response(req,res,next)

  send_banned_response:(req,res,next)=>
    res.status(403)
    res.end()

  handle:(req,res,next)=>
    client_ip = @get_ip(req)
    if @banned_ip(client_ip)
      @_send_banned_response(req,res,next)
    else if @request_is_banned(req)
      @ban_ip(client_ip)
      @_send_banned_response(req,res,next)
    else if req.path is "/banned"
      res.json(@get_ban_data())
    else
      next()
      @total_allowed++
      @recently_allowed++

  add_middleware:(express_app)=>
    express_app.use @handle

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
