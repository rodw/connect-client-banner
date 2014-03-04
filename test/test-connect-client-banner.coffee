should       = require 'should'
fs           = require 'fs'
path         = require 'path'
HOMEDIR      = path.join(__dirname,'..')
LIB_COV      = path.join(HOMEDIR,'lib-cov')
LIB_DIR = if fs.existsSync(LIB_COV) then LIB_COV else path.join(HOMEDIR,'lib')
ConnectClientBanner     = require(path.join(LIB_DIR,'connect-client-banner')).ConnectClientBanner

describe 'ConnectClientBanner',->

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

  banner = new ConnectClientBanner(rules:DEFAULT_RULES)

  it 'blocks some jerks from russia',(done)->
    referrers = [
      'http://www.ooo-gotovie.ru/'
      'http://minecraft-neo.ru/'
      'http://wetgames.ru/'
      'http://buy-tramadolonline.org/'
      'http://ganja-seeds.net/'
      'http://pornoforadult.com/'
      'http://pornogig.com/'
      'http://sexmsk.nl/'
      'http://shiksabd.com/'
      'http://stop-drugs.net/'
      'http://xn--l1aengat.xn--p1ai/'
      'https://itunes.apple.com/us/app/cookies!-i-need-more-cookies!/id723364834'
    ]
    for referrer in referrers
      req = {
        path:'/how-to-umlaut'
        ips: [ '198.22.197.50', '1.2.3.4' ]
        protocol:'http'
        method: 'get'
        header:(name)->
          if /^referr?er$/i.test(name)
            return referrer
          else
            return null
      }
      unless banner.request_is_banned(req)
        should.fail("Expected path #{req.path} and referrer #{req.header("referer")} to be banned but it wasn't.")
    done()


  it 'allows various known good paths',(done)->
    banner = new ConnectClientBanner(rules:DEFAULT_RULES)
    paths = [
      '/graphviz-cookbook/'
      '/graphviz-cookbook'
      '/graphviz-cookbook-recipe-org-chart'
      '/'
      '/status'
      '/how-to-umlaut/'
      '/how-to-umlaut'
      '/the-dust-book/'
      '/the-dust-book'
      '/graphviz-cookbook/blog/2013-12-10-gvprss.html'
      '/img/twitter-16x16-gray.png'
      '/img/noumlaut-16x16-gray.png'
      '/img/ninja-260x260.png'
      '/img/gv-cb-bg-01.png'
      '/css/style.css'
      '/js/script.js'
    ]
    for path in paths
      req = {
        path:path
        ips: [ '198.22.197.50', '1.2.3.4' ]
        protocol:'http'
        method: 'get'
        header:(name)->
          if /^user-agent$/i.test(name)
            return 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/21.0.1180.89 Safari/537.1'
          else
            return null
      }
      if banner.request_is_banned(req)
        should.fail("Expected path #{req.path} NOT to be banned but it was.")
    done()

  it 'blocks various known bad paths',(done)->
    banner = new ConnectClientBanner(rules:DEFAULT_RULES)
    paths = [
      "' or '1'='1"
      "/foo/'/bar"
      '/.git/foo'
      '/.gitignore'
      '/.htaccess'
      '/.svn/foo'
      '//foo'
      '/1;DROP TABLE users'
      '/PMA/'
      '/a'
      '/admin/'
      '/admin/modules/backup/page.backup.php'
      '/administrator/index.php'
      '/cgi-bin/php'
      '/cgi-bin/php5'
      '/config/bd_mpc/offers.json'
      '/css'
      '/css/'
      '/dbadmin/'
      '/foo.asp'
      '/foo.aspx'
      '/foo.cfm'
      '/foo.cgi'
      '/foo.jsp'
      '/foo.php'
      '/foo/"/bar'
      '/foo/$/bar'
      '/foo/%/bar'
      '/foo/&&/bar'
      '/foo/&/bar'
      '/foo/(/bar'
      '/foo/)/bar'
      '/foo/--/bar'
      '/foo/../bar'
      '/foo/;/bar'
      '/foo/</bar'
      '/foo/>/bar'
      '/foo/`/bar'
      '/foo/|/bar'
      '/foo/~/bar'
      '/img'
      '/img/'
      '/invoker/EJBInvokerServlet/'
      '/js'
      '/js/'
      '/manager/html'
      '/muieblackcat'
      '/myadmin/'
      '/myadmin/scripts/setup.php'
      '/mysql-admin/'
      '/mysql/'
      '/mysqladmin/'
      '/mysqlmanager/'
      '/p/m/a/'
      '/php-my-admin/'
      '/php-myadmin/'
      '/phpMyAdmin-2/'
      '/phpMyAdmin/'
      '/phpMyAdmin/scripts/setup.php'
      '/phpMyAdmin2/'
      '/phpmy-admin/'
      '/phpmyadmin/scripts/setup.php'
      '/phpmyadmin2/'
      '/pma/'
      '/pma/scripts/setup.php'
      '/recordings/misc/callme_page.php'
      '/recordings/misc/thaer.php'
      '/sql/'
      '/sqlmanager/'
      '/sqlweb/'
      '/user'
      '/user/soapCaller.bs'
      '/vtigercrm/graph.php'
      '/w00tw00t.at.blackhats.romanian.anti-sec:)'
      '/webadmin/'
      '/webdb/'
      '/websql/'
      '/wp-admin/'
      '/wp-login'
      '/wp-login.php'
      '/wp/wp-admin/'
      'C:\\notes.txt%00'
    ]
    for path in paths
      req = {
        path:path
        ips: [ '198.22.197.50', '1.2.3.4' ]
        protocol:'http'
        method: 'get'
        header:(name)->
          if /^user-agent$/i.test(name)
            return 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/21.0.1180.89 Safari/537.1'
          else
            return null
      }
      unless banner.request_is_banned(req)
        should.fail("Expected path #{req.path} to be banned but it wasn't.")
    done()
