// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_rpc_2.server;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:stack_trace/stack_trace.dart';

import '../error_code.dart' as error_code;
import 'exception.dart';
import 'parameters.dart';
import 'two_way_stream.dart';
import 'utils.dart';

/// A JSON-RPC 2.0 server.
///
/// A server exposes methods that are called by requests, to which it provides
/// responses. Methods can be registered using [registerMethod] and
/// [registerFallback]. Requests can be handled using [handleRequest] and
/// [parseRequest].
///
/// Note that since requests can arrive asynchronously and methods can run
/// asynchronously, it's possible for multiple methods to be invoked at the same
/// time, or even for a single method to be invoked multiple times at once.
class Server {
  TwoWayStream _streams;

  /// The methods registered for this server.
  final _methods = new Map<String, Function>();

  /// The fallback methods for this server.
  ///
  /// These are tried in order until one of them doesn't throw a
  /// [RpcException.methodNotFound] exception.
  final _fallbacks = new Queue<Function>();

  /// Creates a [Server] that reads requests from [requests] and writes
  /// responses to [responses].
  ///
  /// If [requests] is a [StreamSink] as well as a [Stream] (for example, a
  /// `WebSocket`), [responses] may be omitted.
  ///
  /// Note that the server won't begin listening to [requests] until
  /// [Server.listen] is called.
  Server(Stream<String> requests, [StreamSink<String> responses]) {
    _streams = new TwoWayStream("Server", requests, "requests",
        responses, "responses", onInvalidInput: (message, error) {
      _streams.add(new RpcException(error_code.PARSE_ERROR,
          'Invalid JSON: ${error.message}').serialize(message));
    });
  }

  /// Creates a [Server] that reads decoded requests from [requests] and writes
  /// decoded responses to [responses].
  ///
  /// Unlike [new Server], this doesn't read or write JSON strings. Instead, it
  /// reads and writes decoded maps or lists.
  ///
  /// If [requests] is a [StreamSink] as well as a [Stream], [responses] may be
  /// omitted.
  ///
  /// Note that the server won't begin listening to [requests] until
  /// [Server.listen] is called.
  Server.withoutJson(Stream requests, [StreamSink responses])
      : _streams = new TwoWayStream.withoutJson(
            "Server", requests, "requests", responses, "responses");

  /// Users of the library should not use this constructor.
  Server.internal(this._streams);

  /// Starts listening to the underlying stream.
  ///
  /// Returns a [Future] that will complete when the stream is closed or when it
  /// has an error.
  ///
  /// [listen] may only be called once.
  Future listen() => _streams.listen(_handleRequest);

  /// Closes the server's request subscription and response sink.
  ///
  /// Returns a [Future] that completes when all resources have been released.
  ///
  /// A server can't be closed before [listen] has been called.
  Future close() => _streams.close();

  /// Registers a method named [name] on this server.
  ///
  /// [callback] can take either zero or one arguments. If it takes zero, any
  /// requests for that method that include parameters will be rejected. If it
  /// takes one, it will be passed a [Parameters] object.
  ///
  /// [callback] can return either a JSON-serializable object or a Future that
  /// completes to a JSON-serializable object. Any errors in [callback] will be
  /// reported to the client as JSON-RPC 2.0 errors.
  void registerMethod(String name, Function callback) {
    if (_methods.containsKey(name)) {
      throw new ArgumentError('There\'s already a method named "$name".');
    }

    _methods[name] = callback;
  }

  /// Registers a fallback method on this server.
  ///
  /// A server may have any number of fallback methods. When a request comes in
  /// that doesn't match any named methods, each fallback is tried in order. A
  /// fallback can pass on handling a request by throwing a
  /// [RpcException.methodNotFound] exception.
  ///
  /// [callback] can return either a JSON-serializable object or a Future that
  /// completes to a JSON-serializable object. Any errors in [callback] will be
  /// reported to the client as JSON-RPC 2.0 errors. [callback] may send custom
  /// errors by throwing an [RpcException].
  void registerFallback(callback(Parameters parameters)) {
    _fallbacks.add(callback);
  }

  /// Handle a request.
  ///
  /// [request] is expected to be a JSON-serializable object representing a
  /// request sent by a client. This calls the appropriate method or methods for
  /// handling that request and returns a JSON-serializable response, or `null`
  /// if no response should be sent. [callback] may send custom
  /// errors by throwing an [RpcException].
  Future _handleRequest(request) {
    return syncFuture(() {
      if (request is! List) return _handleSingleRequest(request);
      if (request.isEmpty) {
        return new RpcException(error_code.INVALID_REQUEST, 'A batch must '
            'contain at least one request.').serialize(request);
      }

      return Future.wait(request.map(_handleSingleRequest)).then((results) {
        var nonNull = results.where((result) => result != null);
        return nonNull.isEmpty ? null : nonNull.toList();
      });
    }).then(_streams.add);
  }

  /// Handles an individual parsed request.
  Future _handleSingleRequest(request) {
    return syncFuture(() {
      _validateRequest(request);

      var name = request['method'];
      var method = _methods[name];
      if (method == null) method = _tryFallbacks;

      if (method is ZeroArgumentFunction) {
        if (!request.containsKey('params')) return method();
        throw new RpcException.invalidParams('No parameters are allowed for '
            'method "$name".');
      }

      return method(new Parameters(name, request['params']));
    }).then((result) {
      // A request without an id is a notification, which should not be sent a
      // response, even if one is generated on the server.
      if (!request.containsKey('id')) return null;

      return {
        'jsonrpc': '2.0',
        'result': result,
        'id': request['id']
      };
    }).catchError((error, stackTrace) {
      if (error is! RpcException) {
        error = new RpcException(
            error_code.SERVER_ERROR, getErrorMessage(error), data: {
          'full': error.toString(),
          'stack': new Chain.forTrace(stackTrace).toString()
        });
      }

      if (error.code != error_code.INVALID_REQUEST &&
          !request.containsKey('id')) {
        return null;
      } else {
        return error.serialize(request);
      }
    });
  }

  /// Validates that [request] matches the JSON-RPC spec.
  void _validateRequest(request) {
    if (request is! Map) {
      throw new RpcException(error_code.INVALID_REQUEST, 'Request must be '
          'an Array or an Object.');
    }

    if (!request.containsKey('jsonrpc')) {
      throw new RpcException(error_code.INVALID_REQUEST, 'Request must '
          'contain a "jsonrpc" key.');
    }

    if (request['jsonrpc'] != '2.0') {
      throw new RpcException(error_code.INVALID_REQUEST, 'Invalid JSON-RPC '
          'version ${JSON.encode(request['jsonrpc'])}, expected "2.0".');
    }

    if (!request.containsKey('method')) {
      throw new RpcException(error_code.INVALID_REQUEST, 'Request must '
          'contain a "method" key.');
    }

    var method = request['method'];
    if (request['method'] is! String) {
      throw new RpcException(error_code.INVALID_REQUEST, 'Request method must '
          'be a string, but was ${JSON.encode(method)}.');
    }

    var params = request['params'];
    if (request.containsKey('params') && params is! List && params is! Map) {
      throw new RpcException(error_code.INVALID_REQUEST, 'Request params must '
          'be an Array or an Object, but was ${JSON.encode(params)}.');
    }

    var id = request['id'];
    if (id != null && id is! String && id is! num) {
      throw new RpcException(error_code.INVALID_REQUEST, 'Request id must be a '
          'string, number, or null, but was ${JSON.encode(id)}.');
    }
  }

  /// Try all the fallback methods in order.
  Future _tryFallbacks(Parameters params) {
    var iterator = _fallbacks.toList().iterator;

    _tryNext() {
      if (!iterator.moveNext()) {
        return new Future.error(
            new RpcException.methodNotFound(params.method),
            new Chain.current());
      }

      return syncFuture(() => iterator.current(params)).catchError((error) {
        if (error is! RpcException) throw error;
        if (error.code != error_code.METHOD_NOT_FOUND) throw error;
        return _tryNext();
      });
    }

    return _tryNext();
  }
}
