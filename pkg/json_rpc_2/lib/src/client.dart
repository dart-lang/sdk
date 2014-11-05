// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_rpc_2.client;

import 'dart:async';

import 'package:stack_trace/stack_trace.dart';

import 'exception.dart';
import 'two_way_stream.dart';
import 'utils.dart';

/// A JSON-RPC 2.0 client.
///
/// A client calls methods on a server and handles the server's responses to
/// those method calls. Methods can be called with [sendRequest], or with
/// [sendNotification] if no response is expected.
class Client {
  final TwoWayStream _streams;

  /// The next request id.
  var _id = 0;

  /// The current batch of requests to be sent together.
  ///
  /// Each element is a JSON-serializable object.
  List _batch;

  /// The map of request ids for pending requests to [Completer]s that will be
  /// completed with those requests' responses.
  final _pendingRequests = new Map<int, Completer>();

  /// Creates a [Client] that writes requests to [requests] and reads responses
  /// from [responses].
  ///
  /// If [responses] is a [StreamSink] as well as a [Stream] (for example, a
  /// `WebSocket`), [requests] may be omitted.
  ///
  /// Note that the client won't begin listening to [responses] until
  /// [Client.listen] is called.
  Client(Stream<String> responses, [StreamSink<String> requests])
      : _streams = new TwoWayStream(
            "Client", responses, "responses", requests, "requests");

  /// Creates a [Client] that writes decoded responses to [responses] and reads
  /// decoded requests from [requests].
  ///
  /// Unlike [new Client], this doesn't read or write JSON strings. Instead, it
  /// reads and writes decoded maps or lists.
  ///
  /// If [responses] is a [StreamSink] as well as a [Stream], [requests] may be
  /// omitted.
  ///
  /// Note that the client won't begin listening to [responses] until
  /// [Client.listen] is called.
  Client.withoutJson(Stream responses, [StreamSink requests])
      : _streams = new TwoWayStream.withoutJson(
            "Client", responses, "responses", requests, "requests");

  /// Users of the library should not use this constructor.
  Client.internal(this._streams);

  /// Starts listening to the underlying stream.
  ///
  /// Returns a [Future] that will complete when the stream is closed or when it
  /// has an error.
  ///
  /// [listen] may only be called once.
  Future listen() => _streams.listen(_handleResponse);

  /// Closes the server's request sink and response subscription.
  ///
  /// Returns a [Future] that completes when all resources have been released.
  ///
  /// A client can't be closed before [listen] has been called.
  Future close() => _streams.close();

  /// Sends a JSON-RPC 2 request to invoke the given [method].
  ///
  /// If passed, [parameters] is the parameters for the method. This must be
  /// either an [Iterable] (to pass parameters by position) or a [Map] with
  /// [String] keys (to pass parameters by name). Either way, it must be
  /// JSON-serializable.
  ///
  /// If the request succeeds, this returns the response result as a decoded
  /// JSON-serializable object. If it fails, it throws an [RpcException]
  /// describing the failure.
  Future sendRequest(String method, [parameters]) {
    var id = _id++;
    _send(method, parameters, id);

    var completer = new Completer.sync();
    _pendingRequests[id] = completer;
    return completer.future;
  }

  /// Sends a JSON-RPC 2 request to invoke the given [method] without expecting
  /// a response.
  ///
  /// If passed, [parameters] is the parameters for the method. This must be
  /// either an [Iterable] (to pass parameters by position) or a [Map] with
  /// [String] keys (to pass parameters by name). Either way, it must be
  /// JSON-serializable.
  ///
  /// Since this is just a notification to which the server isn't expected to
  /// send a response, it has no return value.
  void sendNotification(String method, [parameters]) =>
      _send(method, parameters);

  /// A helper method for [sendRequest] and [sendNotification].
  ///
  /// Sends a request to invoke [method] with [parameters]. If [id] is given,
  /// the request uses that id.
  void _send(String method, parameters, [int id]) {
    if (parameters is Iterable) parameters = parameters.toList();
    if (parameters is! Map && parameters is! List && parameters != null) {
      throw new ArgumentError('Only maps and lists may be used as JSON-RPC '
          'parameters, was "$parameters".');
    }

    var message = {
      "jsonrpc": "2.0",
      "method": method
    };
    if (id != null) message["id"] = id;
    if (parameters != null) message["params"] = parameters;

    if (_batch != null) {
      _batch.add(message);
    } else {
      _streams.add(message);
    }
  }

  /// Runs [callback] and batches any requests sent until it returns.
  ///
  /// A batch of requests is sent in a single message on the underlying stream,
  /// and the responses are likewise sent back in a single message.
  ///
  /// [callback] may be synchronous or asynchronous. If it returns a [Future],
  /// requests will be batched until that Future returns; otherwise, requests
  /// will only be batched while synchronously executing [callback].
  ///
  /// If this is called in the context of another [withBatch] call, it just
  /// invokes [callback] without creating another batch. This means that
  /// responses are batched until the first batch ends.
  withBatch(callback()) {
    if (_batch != null) return callback();

    _batch = [];
    return tryFinally(callback, () {
      _streams.add(_batch);
      _batch = null;
    });
  }

  /// Handles a decoded response from the server.
  void _handleResponse(response) {
    if (response is List) {
      response.forEach(_handleSingleResponse);
    } else {
      _handleSingleResponse(response);
    }
  }

  /// Handles a decoded response from the server after batches have been
  /// resolved.
  void _handleSingleResponse(response) {
    if (!_isResponseValid(response)) return;
    var completer = _pendingRequests.remove(response["id"]);
    if (response.containsKey("result")) {
      completer.complete(response["result"]);
    } else {
      completer.completeError(new RpcException(
            response["error"]["code"],
            response["error"]["message"],
            data: response["error"]["data"]),
          new Chain.current());
    }
  }

  /// Determines whether the server's response is valid per the spec.
  bool _isResponseValid(response) {
    if (response is! Map) return false;
    if (response["jsonrpc"] != "2.0") return false;
    if (!_pendingRequests.containsKey(response["id"])) return false;
    if (response.containsKey("result")) return true;

    if (!response.containsKey("error")) return false;
    var error = response["error"];
    if (error is! Map) return false;
    if (error["code"] is! int) return false;
    if (error["message"] is! String) return false;
    return true;
  }
}
