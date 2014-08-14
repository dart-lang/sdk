## 1.1.0

* Add support for `HttpServer.defaultResponseHeaders`.

## 1.0.2

* Remove the workaround for [issue 19815][].

## 1.0.1

* Ignore errors from one of the servers if others are still bound. In
  particular, this works around [issue 19815][] on some Windows machines where
  IPv6 failure isn't discovered until we try to connect to the socket.

[issue 19815]: http://code.google.com/p/dart/issues/detail?id=19815
