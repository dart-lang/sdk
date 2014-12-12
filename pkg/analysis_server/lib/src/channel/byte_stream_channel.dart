// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library channel.byte_stream;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/protocol.dart';
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
    Stream jsonStream = input.transform(
        (new Utf8Codec()).decoder).transform(
            new LineSplitter()).transform(
                new JsonStreamDecoder()).where((json) => json is Map).asBroadcastStream();
    responseStream = jsonStream.where(
        (json) =>
            json[Notification.EVENT] ==
                null).transform(new ResponseConverter()).asBroadcastStream();
    notificationStream = jsonStream.where(
        (json) =>
            json[Notification.EVENT] !=
                null).transform(new NotificationConverter()).asBroadcastStream();
  }

  @override
  Future close() {
    return output.close();
  }

  @override
  Future<Response> sendRequest(Request request) {
    String id = request.id;
    output.write(JSON.encode(request.toJson()) + '\n');
    return responseStream.firstWhere((Response response) => response.id == id);
  }
}

/**
 * Instances of the class [ByteStreamServerChannel] implement a
 * [ServerCommunicationChannel] that uses a stream and a sink (typically,
 * standard input and standard output) to communicate with clients.
 */
class ByteStreamServerChannel implements ServerCommunicationChannel {
  /**
   * Value of [_outputState] indicating that there is no outstanding data in
   * [_pendingOutput], and that the most recent flush of [_output] has
   * completed.
   */
  static const int _STATE_IDLE = 0;

  /**
   * Value of [_outputState] indicating that there is outstanding data in
   * [_pendingOutput], and that the most recent flush of [_output] has
   * completed; therefore a microtask has been scheduled to send the data.
   */
  static const int _STATE_MICROTASK_PENDING = 1;

  /**
   * Value of [_outputState] indicating that data has been sent to the
   * [_output] stream and flushed, but the flush has not completed, so we must
   * wait for it to complete before sending more data.  There may or may not be
   * outstanding data in [_pendingOutput].
   */
  static const int _STATE_FLUSH_PENDING = 2;

  final Stream input;

  final IOSink _output;

  /**
   * The instrumentation service that is to be used by this analysis server.
   */
  final InstrumentationService instrumentationService;

  /**
   * Completer that will be signalled when the input stream is closed.
   */
  final Completer _closed = new Completer();

  /**
   * State of the output stream (see constants above).
   */
  int _outputState = _STATE_IDLE;

  /**
   * List of strings that need to be sent to [_output] at the next available
   * opportunity.
   */
  List<String> _pendingOutput = <String>[];

  /**
   * True if [close] has been called.
   */
  bool _closeRequested = false;

  ByteStreamServerChannel(this.input, this._output,
      this.instrumentationService);

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
      if (_outputState == _STATE_IDLE) {
        assert(!_closed.isCompleted);
        _closed.complete();
      } else {
        // Nothing to do.  [_flushCompleted] will call _closed.complete() after
        // the flush completes.
      }
    }
  }

  @override
  void listen(void onRequest(Request request), {Function onError, void
      onDone()}) {
    input.transform(
        (new Utf8Codec()).decoder).transform(
            new LineSplitter()).listen(
                (String data) => _readRequest(data, onRequest),
                onError: onError,
                onDone: () {
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
    ServerCommunicationChannel.ToJson.start();
    String jsonEncoding = JSON.encode(notification.toJson());
    ServerCommunicationChannel.ToJson.stop();
    _outputLine(jsonEncoding);
    instrumentationService.logNotification(jsonEncoding);
  }

  @override
  void sendResponse(Response response) {
    // Don't send any further responses after the communication channel is
    // closed.
    if (_closeRequested) {
      return;
    }
    ServerCommunicationChannel.ToJson.start();
    String jsonEncoding = JSON.encode(response.toJson());
    ServerCommunicationChannel.ToJson.stop();
    _outputLine(jsonEncoding);
    instrumentationService.logResponse(jsonEncoding);
  }

  /**
   * Callback invoked after a flush of [_output] completes.  Closes the stream
   * if necessary.  Otherwise schedules additional pending output.
   */
  void _flushCompleted(_) {
    assert(_outputState == _STATE_FLUSH_PENDING);
    if (_pendingOutput.isNotEmpty) {
      _output.write(_pendingOutput.join());
      _output.flush().then(_flushCompleted);
      _pendingOutput.clear();
      // Since we've done another flush, stay in _STATE_FLUSH_PENDING.
    } else {
      _outputState = _STATE_IDLE;
      if (_closeRequested) {
        assert(!_closed.isCompleted);
        _closed.complete();
      }
    }
  }

  /**
   * Microtask that writes pending output to the output stream and flushes it.
   */
  void _microtask() {
    assert(_outputState == _STATE_MICROTASK_PENDING);
    _output.write(_pendingOutput.join());
    _output.flush().then(_flushCompleted);
    _pendingOutput.clear();
    _outputState = _STATE_FLUSH_PENDING;
  }

  /**
   * Send the string [s] to [_output] followed by a newline.
   */
  void _outputLine(String s) {
    _pendingOutput.add(s);
    _pendingOutput.add('\n');
    if (_outputState == _STATE_IDLE) {
      // Don't send the output just yet; schedule a microtask to do it, so that
      // if caller decides to output additional lines, they will get sent in
      // the same call to _output.write().
      new Future.microtask(_microtask);
      _outputState = _STATE_MICROTASK_PENDING;
    }
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
    instrumentationService.logRequest(data);
    // Parse the string as a JSON descriptor and process the resulting
    // structure as a request.
    ServerCommunicationChannel.FromJson.start();
    Request request = new Request.fromString(data);
    ServerCommunicationChannel.FromJson.stop();
    if (request == null) {
      sendResponse(new Response.invalidRequestFormat());
      return;
    }
    onRequest(request);
  }
}
