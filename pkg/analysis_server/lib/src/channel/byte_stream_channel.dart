// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/utilities/request_statistics.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';

/// Instances of the class [ByteStreamClientChannel] implement a
/// [ClientCommunicationChannel] that uses a stream and a sink (typically,
/// standard input and standard output) to communicate with servers.
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
        .transform(LineSplitter())
        .transform(JsonStreamDecoder())
        .where((json) => json is Map)
        .asBroadcastStream();
    responseStream = jsonStream
        .where((json) => json[Notification.EVENT] == null)
        .transform(ResponseConverter())
        .asBroadcastStream();
    notificationStream = jsonStream
        .where((json) => json[Notification.EVENT] != null)
        .transform(NotificationConverter())
        .asBroadcastStream();
  }

  @override
  Future close() {
    return output.close();
  }

  @override
  Future<Response> sendRequest(Request request) async {
    var id = request.id;
    output.write(json.encode(request.toJson()) + '\n');
    return await responseStream
        .firstWhere((Response response) => response.id == id);
  }
}

/// Instances of the class [ByteStreamServerChannel] implement a
/// [ServerCommunicationChannel] that uses a stream and a sink (typically,
/// standard input and standard output) to communicate with clients.
class ByteStreamServerChannel implements ServerCommunicationChannel {
  final Stream _input;

  final IOSink _output;

  /// The instrumentation service that is to be used by this analysis server.
  final InstrumentationService _instrumentationService;

  /// The helper for recording request / response statistics.
  final RequestStatisticsHelper _requestStatistics;

  /// Completer that will be signalled when the input stream is closed.
  final Completer _closed = Completer();

  /// True if [close] has been called.
  bool _closeRequested = false;

  ByteStreamServerChannel(
      this._input, this._output, this._instrumentationService,
      {RequestStatisticsHelper requestStatistics})
      : _requestStatistics = requestStatistics {
    _requestStatistics?.serverChannel = this;
  }

  /// Future that will be completed when the input stream is closed.
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
  void listen(void Function(Request request) onRequest,
      {Function onError, void Function() onDone}) {
    _input.transform(const Utf8Decoder()).transform(LineSplitter()).listen(
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
    var jsonEncoding = json.encode(notification.toJson());
    _outputLine(jsonEncoding);
    if (!identical(notification.event, 'server.log')) {
      _instrumentationService.logNotification(jsonEncoding);
      _requestStatistics?.logNotification(notification);
    }
  }

  @override
  void sendResponse(Response response) {
    // Don't send any further responses after the communication channel is
    // closed.
    if (_closeRequested) {
      return;
    }
    _requestStatistics?.addResponse(response);
    var jsonEncoding = json.encode(response.toJson());
    _outputLine(jsonEncoding);
    _instrumentationService.logResponse(jsonEncoding);
  }

  /// Send the string [s] to [_output] followed by a newline.
  void _outputLine(String s) {
    runZonedGuarded(() {
      _output.writeln(s);
    }, (e, s) {
      close();
    });
  }

  /// Read a request from the given [data] and use the given function to handle
  /// the request.
  void _readRequest(Object data, void Function(Request request) onRequest) {
    // Ignore any further requests after the communication channel is closed.
    if (_closed.isCompleted) {
      return;
    }
    _instrumentationService.logRequest(data);
    // Parse the string as a JSON descriptor and process the resulting
    // structure as a request.
    var request = Request.fromString(data);
    if (request == null) {
      sendResponse(Response.invalidRequestFormat());
      return;
    }
    _requestStatistics?.addRequest(request);
    onRequest(request);
  }
}
