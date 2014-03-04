# Connect Client Banner

[Connect](https://github.com/senchalabs/connect)/[Express](http://expressjs.com/) middleware for temporarily banning ill-behaving clients.

## Overview

If you take a cursory look at your web server logs you'll notice a large number of requests for paths like `/admin/`, `/manager`, `/mysql`, `/wp`, `/servlet`, `/cgi-bin`, etc., even if those paths don't do anything on your particular site.

These are web robots scanning for known vulnerabilities in common software (Drupal, MySQL WebAdmin, Tomcat, WordPress, etc.).

These robots are annoying (and resource-consuming) at best, and potentially dangerous at worst.

***ConnectClientBanner*** is a simple middleware application that provides a quick-and-easy way to address these and other "bad clients" within stand-alone [Node.js](http://nodejs.org)/[Connect](https://github.com/senchalabs/connect)/[Express](http://expressjs.com/) applications.

*ConnectClientBanner* compares each request to a collection of "patterns" or "filters" that test arbitrary request attributes (such as the request path, the user-agent header, the client's IP address, etc.).  When a match is found, *ConnectClientBanner* will temporarily return a (customizable) "forbidden" response to all requests from that client's IP address.

It's a bit like the penalty box in hockey or rugby--a client that commits an "offense" is banned from the site for the duration of a cooling-off period.
