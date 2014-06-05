An implementation of `dart:io`'s [HttpServer][] that wraps multiple servers and
forwards methods to all of them. It's useful for serving the same application on
multiple network interfaces while still having a unified way of controlling the
servers. In particular, it supports serving on both the IPv4 and IPv6 loopback
addresses using [HttpMultiServer.loopback][].

```dart
import 'package:http_multi_server/http_multi_server.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() {
  // Both http://127.0.0.1:8080 and http://[::1]:8080 will be bound to the same
  // server.
  HttpMultiServer.loopback(8080).then((server) {
    shelf_io.serveRequests(server, (request) {
      return new shelf.Response.ok("Hello, world!");
    });
  });
}
```

[HttpServer]: https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/dart-io.HttpServer

[HttpMultiServer.loopback]: https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/http_multi_server/http_multi_server.HttpMultiServer#id_loopback
