// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:devtools_shared/devtools_server.dart';
import 'package:json_rpc_2/src/server.dart' as json_rpc;
import 'package:sse/src/server/sse_handler.dart';
import 'package:stream_channel/stream_channel.dart';

class LoggingMiddlewareSink<S> implements StreamSink<S> {
  LoggingMiddlewareSink(this.sink);

  @override
  void add(S event) {
    print('DevTools SSE response: $event');
    sink.add(event);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    print('DevTools SSE error response: $error');
    sink.addError(error);
  }

  @override
  Future addStream(Stream<S> stream) {
    return sink.addStream(stream);
  }

  @override
  Future close() => sink.close();

  @override
  Future get done => sink.done;

  final StreamSink sink;
}

/// Represents a DevTools client connection to the DevTools server API.
class DevToolsClient {
  DevToolsClient.fromSSEConnection(
    SseConnection sse,
    bool loggingEnabled,
  ) {
    Stream<String> stream = sse.stream;
    StreamSink sink = sse.sink;

    if (loggingEnabled) {
      stream = stream.map<String>((String e) {
        print('DevTools SSE request: $e');
        return e;
      });
      sink = LoggingMiddlewareSink(sink);
    }

    _server = json_rpc.Server(
      StreamChannel(stream, sink as StreamSink<String>),
      strictProtocolChecks: false,
    );
    _registerJsonRpcMethods();
    _server.listen();
  }

  void _registerJsonRpcMethods() {
    _server.registerMethod('connected', (parameters) {
      // Nothing to do here.
    });

    _server.registerMethod('currentPage', (parameters) {
      // Nothing to do here.
    });

    _server.registerMethod('disconnected', (parameters) {
      // Nothing to do here.
    });

    _server.registerMethod('getPreferenceValue', (parameters) {
      final key = parameters['key'].asString;
      final value = ServerApi.devToolsPreferences.properties[key];
      return value;
    });

    _server.registerMethod('setPreferenceValue', (parameters) {
      final key = parameters['key'].asString;
      final value = parameters['value'].value;
      ServerApi.devToolsPreferences.properties[key] = value;
    });
  }

  late json_rpc.Server _server;
}
