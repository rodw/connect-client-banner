[

  { attr:'path', is:'/admin/login.php' },                 // Bans all requests to the exact path '/admin/login.php'.

  { attr:'path', matches:/^\/phpmyadmin/i },              // Bans all requests whose path starts with the string '/phpmyadmin', ignoring case.

  { header:'user-agent', matches:/ZmEu/i },               // Bans all requests with a user-agent header that contains the string 'ZmEu', ignoring case

  { AND: [                                                // Bans all requests where...
    { header:'user-agent', matches:/spider/i },           // ...the user-agent header contains the string 'spider',
    { attr:'host', matches:/\.edu$/ },                    // ...the host name ends with '.edu',
    { attr:'path', matches:/\.((jpe?g)|(gif)|(png))$/ }   // ...AND the path ends with .jpg, .jpeg, .gif or .png
  ] },

  { AND: [                                                // Bans all requests where...
    { attr:'port', '>':80 },                              // ...the port number greater than 80
    { UNLESS: { attr:'protocol', matches:/^https:?$/i } } // ...UNLESS the protocol is HTTPS.
  ] }

]
