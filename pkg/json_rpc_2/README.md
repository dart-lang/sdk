A library that implements the [JSON-RPC 2.0 spec][spec].

[spec]: http://www.jsonrpc.org/specification

## Server

A JSON-RPC 2.0 server exposes a set of methods that can be called by clients.
These methods can be registered using `Server.registerMethod`:

```dart
import "package:json_rpc_2/json_rpc_2.dart" as json_rpc;

var server = new json_rpc.Server();

// Any string may be used as a method name. JSON-RPC 2.0 methods are
// case-sensitive.
var i = 0;
server.registerMethod("count", () {
  // Just return the value to be sent as a response to the client. This can be
  // anything JSON-serializable, or a Future that completes to something
  // JSON-serializable.
  return i++;
});

// Methods can take parameters. They're presented as a [Parameters] object which
// makes it easy to validate that the expected parameters exist.
server.registerMethod("echo", (params) {
  // If the request doesn't have a "message" parameter, this will automatically
  // send a response notifying the client that the request was invalid.
  return params.getNamed("message");
});

// [Parameters] has methods for verifying argument types.
server.registerMethod("subtract", (params) {
  // If "minuend" or "subtrahend" aren't numbers, this will reject the request.
  return params.getNum("minuend") - params.getNum("subtrahend");
});

// [Parameters] also supports optional arguments.
server.registerMethod("sort", (params) {
  var list = params.getList("list");
  list.sort();
  if (params.getBool("descending", orElse: () => false)) {
    return params.list.reversed;
  } else {
    return params.list;
  }
});

// A method can send an error response by throwing a `json_rpc.RpcException`.
// Any positive number may be used as an application-defined error code.
const DIVIDE_BY_ZERO = 1;
server.registerMethod("divide", (params) {
  var divisor = params.getNum("divisor");
  if (divisor == 0) {
    throw new json_rpc.RpcException(DIVIDE_BY_ZERO, "Cannot divide by zero.");
  }

  return params.getNum("dividend") / divisor;
});
```

Once you've registered your methods, you can handle requests with
`Server.parseRequest`:

```dart
import 'dart:io';

WebSocket.connect('ws://localhost:4321').then((socket) {
  socket.listen((message) {
    server.parseRequest(message).then((response) {
      if (response != null) socket.add(response);
    });
  });
});
```

If you're communicating with objects that haven't been serialized to a string,
you can also call `Server.handleRequest` directly:

```dart
import 'dart:isolate';

var receive = new ReceivePort();
Isolate.spawnUri('path/to/client.dart', [], receive.sendPort).then((_) {
  receive.listen((message) {
    server.handleRequest(message['request']).then((response) {
      if (response != null) message['respond'].send(response);
    });
  });
})
```

## Client

Currently this package does not contain an implementation of a JSON-RPC 2.0
client.

