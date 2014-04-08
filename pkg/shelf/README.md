## Web Server Middleware for Dart

## Introduction

**Shelf** makes it easy to create and compose **web servers** and **parts of web
servers**. How?

* Expose a small set of simple types.
* Map server logic into a simple function: a single argument for the request,
the response is the return value.
* Trivially mix and match synchronous and asynchronous processing.
* Flexibliity to return a simple string or a byte stream with the same model.

## Example

See `example/example_server.dart`

```dart
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;

void main() {
  var handler = const shelf.Stack().addMiddleware(shelf.logRequests())
      .addHandler(_echoRequest);

  io.serve(handler, 'localhost', 8080).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  });
}

shelf.Response _echoRequest(shelf.Request request) {
  return new shelf.Response.ok('Request for "${request.url}"');
}
```

## Inspiration

* [Connect](http://www.senchalabs.org/connect/) for NodeJS.
    * Read [this great write-up](http://howtonode.org/connect-it) to understand
      the overall philosophy of all of these models.
* [Rack](http://rack.github.io/) for Ruby.
* [WSGI](http://legacy.python.org/dev/peps/pep-3333/) for Python.
