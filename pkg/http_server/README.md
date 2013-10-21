Library of HTTP server classes.

This package contains a set of high-level classes that, together with
HttpServer, makes is easy to provide content through HTTP servers.

## Virtual Directory

The VirtualDirectory class makes it possible to easy serve static content from
the drive. It supports:

 *  Range-based request, making it possible to pause/resume downloads and stream
    videos.
 *  If-Modified-Since based caching.
 *  Automatic GZip-compression of content.
 *  Ability to follow links within, either throughout the system or in a jailed
    root.
 *  Optional directory listing.

 The following example shows how to set up a Virtual Directory of a given path

    var virtualDirectory = new VirtualDirectory('/var/www/');
    virtualDirectory.serve(new HttpServer('0.0.0.0', 8080));

See [VirtualDirectory](
http://api.dartlang.org/docs/http_server/VirtualDirectory.html)
for more info about how to customize the class.

## Virtual Host

The VirtualHost class makes it possible to serve multiple hosts on the same
address, by using the `Host` field of the incoming requests. It also provides
the ability to work on wildcards for sub-domains.

    var virtualHost = new VirtualHost(server);
    // Filter out on a specific host
    var stream1 = virtualServer.addHost('static.myserver.com');
    // Wildcard for any other sub-domains.
    var stream2 = virtualServer.addHost('*.myserver.com');
    // Requets not matching any hosts.
    var stream3 = virtualServer.unhandled;

See [VirtualHost](
http://api.dartlang.org/docs/http_server/VirtualHost.html)
for more information.
