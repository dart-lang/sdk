## 1.0.0

* Add a `Client` class for communicating with external JSON-RPC 2.0 servers.

## 0.1.0

* Remove `Server.handleRequest()` and `Server.parseRequest()`. Instead, `new
  Server()` takes a `Stream` and a `StreamSink` and uses those behind-the-scenes
  for its communication.

* Add `Server.listen()`, which causes the server to begin listening to the
  underlying request stream.

* Add `Server.close()`, which closes the underlying request stream and response
  sink.

## 0.0.2+3

* Widen the version constraint for `stack_trace`.

## 0.0.2+2

* Fix error response to include data from `RpcException` when not a map.
