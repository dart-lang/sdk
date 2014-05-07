# http

A composable, Future-based library for making HTTP requests.

This package contains a set of high-level functions and classes that make it
easy to consume HTTP resources. It's platform-independent, and can be used on
both the command-line and the browser. Currently the global utility functions
are unsupported on the browser; see "Using on the Browser" below.

## Using

The easiest way to use this library is via the top-level functions, although
they currently only work on platforms where `dart:io` is available. They allow
you to make individual HTTP requests with minimal hassle:

```dart
import 'package:http/http.dart' as http;

var url = "http://example.com/whatsit/create";
http.post(url, body: {"name": "doodle", "color": "blue"})
    .then((response) {
  print("Response status: ${response.statusCode}");
  print("Response body: ${response.body}");
});

http.read("http://example.com/foobar.txt").then(print);
```

If you're making multiple requests to the same server, you can keep open a
persistent connection by using a [Client][] rather than making one-off requests.
If you do this, make sure to close the client when you're done:

```dart
var client = new http.Client();
client.post(
    "http://example.com/whatsit/create",
    body: {"name": "doodle", "color": "blue"})
  .then((response) => client.get(response.bodyFields['uri']))
  .then((response) => print(response.body))
  .whenComplete(client.close);
```

You can also exert more fine-grained control over your requests and responses by
creating [Request][] or [StreamedRequest][] objects yourself and passing them to
[Client.send][].

[Request]: https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/http/http.Request

[StreamedRequest]: https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/http/http.StreamedRequest

[Client.send]: https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/http/http.Client#id_send

This package is designed to be composable. This makes it easy for external
libraries to work with one another to add behavior to it. Libraries wishing to
add behavior should create a subclass of [BaseClient][] that wraps another
[Client][] and adds the desired behavior:

[BaseClient]: https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/http/http.BaseClient

[Client]: https://api.dartlang.org/apidocs/channels/stable/dartdoc-viewer/http/http.Client

```dart
class UserAgentClient extends http.BaseClient {
  final String userAgent;
  final http.Client _inner;

  UserAgentClient(this.userAgent, this._inner);

  Future<StreamedResponse> send(BaseRequest request) {
    request.headers['user-agent'] = userAgent;
    return _inner.send(request);
  }
}
```

## Using on the Browser

The HTTP library can be used on the browser via the [BrowserClient][] class in
`package:http/browser_client.dart`. This client translates requests into
XMLHttpRequests. For example:

```dart
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

var client = new BrowserClient();
var url = "/whatsit/create";
client.post(url, body: {"name": "doodle", "color": "blue"})
    .then((response) {
  print("Response status: ${response.statusCode}");
  print("Response body: ${response.body}");
});
```

## Filing issues

Please file issues for the http package at [http://dartbug.com/new][bugs].

[bugs]: http://dartbug.com/new
[docs]: https://api.dartlang.org/docs/channels/dev/latest/http.html
