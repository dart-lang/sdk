// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';

/**
 * Instances of the class [ByteStreamClientChannel] implement a
 * [ClientCommunicationChannel] that uses a stream and a sink (typically,
 * standard input and standard output) to communicate with servers.
 */
class ByteStreamClientChannel implements ClientCommunicationChannel {
  final Stream input;
  final IOSink output;

  @override
  Stream<Response> responseStream;

  @override
  Stream<Notification> notificationStream;

  ByteStreamClientChannel(this.input, this.output) {
    Stream jsonStream = input
        .transform(const Utf8Decoder())
        .transform(new LineSplitter())
        .transform(new JsonStreamDecoder())
        .where((json) => json is Map)
        .asBroadcastStream();
    responseStream = jsonStream
        .where((json) => json[Notification.EVENT] == null)
        .transform(new ResponseConverter())
        .asBroadcastStream();
    notificationStream = jsonStream
        .where((json) => json[Notification.EVENT] != null)
        .transform(new NotificationConverter())
        .asBroadcastStream();
  }

  @override
  Future close() {
    return output.close();
  }

  @override
  Future<Response> sendRequest(Request request) async {
    String id = request.id;
    output.write(JSON.encode(request.toJson()) + '\n');
    return await responseStream
        .firstWhere((Response response) => response.id == id);
  }
}

/**
 * Instances of the class [ByteStreamServerChannel] implement a
 * [ServerCommunicationChannel] that uses a stream and a sink (typically,
 * standard input and standard output) to communicate with clients.
 */
class ByteStreamServerChannel implements ServerCommunicationChannel {
  final Stream _input;

  final IOSink _output;

  /**
   * The instrumentation service that is to be used by this analysis server.
   */
  final InstrumentationService _instrumentationService;

  /**
   * Completer that will be signalled when the input stream is closed.
   */
  final Completer _closed = new Completer();

  /**
   * True if [close] has been called.
   */
  bool _closeRequested = false;

  ByteStreamServerChannel(
      this._input, this._output, this._instrumentationService);

  /**
   * Future that will be completed when the input stream is closed.
   */
  Future get closed {
    return _closed.future;
  }

  @override
  void close() {
    if (!_closeRequested) {
      _closeRequested = true;
      assert(!_closed.isCompleted);
      _closed.complete();
    }
  }

  @override
  void listen(void onRequest(Request request),
      {Function onError, void onDone()}) {
    _input.transform(const Utf8Decoder()).transform(new LineSplitter()).listen(
        (String data) => _readRequest(data, onRequest),
        onError: onError, onDone: () {
      close();
      onDone();
    });
  }

  @override
  void sendNotification(Notification notification) {
    // Don't send any further notifications after the communication channel is
    // closed.
    if (_closeRequested) {
      return;
    }
    ServerPerformanceStatistics.serverChannel.makeCurrentWhile(() {
      String jsonEncoding = JSON.encode(notification.toJson());
      _outputLine(jsonEncoding);
      _instrumentationService.logNotification(jsonEncoding);
    });
  }

  @override
  void sendResponse(Response response) {
    // Don't send any further responses after the communication channel is
    // closed.
    if (_closeRequested) {
      return;
    }
    ServerPerformanceStatistics.serverChannel.makeCurrentWhile(() {
      String jsonEncoding = JSON.encode(response.toJson());
      _outputLine(jsonEncoding);
      _instrumentationService.logResponse(jsonEncoding);
    });
  }

  /**
   * Send the string [s] to [_output] followed by a newline.
   */
  void _outputLine(String s) {
    _output.writeln(s);
  }

  /**
   * Read a request from the given [data] and use the given function to handle
   * the request.
   */
  void _readRequest(Object data, void onRequest(Request request)) {
    // Ignore any further requests after the communication channel is closed.
    if (_closed.isCompleted) {
      return;
    }
    ServerPerformanceStatistics.serverChannel.makeCurrentWhile(() {
      _instrumentationService.logRequest(data);
      // Parse the string as a JSON descriptor and process the resulting
      // structure as a request.
      Request request = new Request.fromString(data);
      if (request == null) {
        sendResponse(new Response.invalidRequestFormat());
        return;
      }
      onRequest(request);
    });
  }
}
