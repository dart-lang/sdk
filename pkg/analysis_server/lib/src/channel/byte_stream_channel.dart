// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/src/channel/channel.dart';
import 'package:analysis_server/src/utilities/request_statistics.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';

/// Instances of the class [ByteStreamClientChannel] implement a
/// [ClientCommunicationChannel] that uses a stream and a sink (typically,
/// standard input and standard output) to communicate with servers.
class ByteStreamClientChannel implements ClientCommunicationChannel {
  final IOSink output;

  @override
  Stream<Response> responseStream;

  @override
  Stream<Notification> notificationStream;

  factory ByteStreamClientChannel(Stream<List<int>> input, IOSink output) {
    var jsonStream =
        input
            .transform(const Utf8Decoder())
            .transform(LineSplitter())
            .transform(JsonStreamDecoder())
            .where((json) => json is Map<String, Object?>)
            .cast<Map<String, Object?>>()
            .asBroadcastStream();
    var responseStream =
        jsonStream
            .where((json) => json[Notification.EVENT] == null)
            .transform(ResponseConverter())
            .where((response) => response != null)
            .cast<Response>()
            .asBroadcastStream();
    var notificationStream =
        jsonStream
            .where((json) => json[Notification.EVENT] != null)
            .transform(NotificationConverter())
            .asBroadcastStream();
    return ByteStreamClientChannel._(
      output,
      responseStream,
      notificationStream,
    );
  }

  ByteStreamClientChannel._(
    this.output,
    this.responseStream,
    this.notificationStream,
  );

  @override
  Future<void> close() {
    return output.close();
  }

  @override
  Future<Response> sendRequest(Request request) async {
    var id = request.id;
    output.write('${json.encode(request.toJson())}\n');
    return await responseStream.firstWhere(
      (Response response) => response.id == id,
    );
  }
}

/// Instances of the subclasses of [ByteStreamServerChannel] implement a
/// [ServerCommunicationChannel] that uses a stream and a sink to communicate
/// with clients.
abstract class ByteStreamServerChannel implements ServerCommunicationChannel {
  /// The instrumentation service that is to be used by this analysis server.
  final InstrumentationService _instrumentationService;

  /// The helper for recording request / response statistics.
  final RequestStatisticsHelper? _requestStatistics;

  /// Completer that will be signalled when the input stream is closed.
  final Completer<void> _closed = Completer();

  /// True if [close] has been called.
  bool _closeRequested = false;

  @override
  late final Stream<RequestOrResponse> requests = _lines.transform(
    StreamTransformer.fromHandlers(
      handleData: _readRequest,
      handleDone: (sink) {
        close();
        sink.close();
      },
    ),
  );

  ByteStreamServerChannel(
    this._instrumentationService, {
    RequestStatisticsHelper? requestStatistics,
  }) : _requestStatistics = requestStatistics {
    _requestStatistics?.serverChannel = this;
  }

  /// Future that will be completed when the input stream is closed.
  Future<void> get closed {
    return _closed.future;
  }

  Stream<String> get _lines;

  IOSink get _output;

  @override
  void close() {
    if (!_closeRequested) {
      _closeRequested = true;
      assert(!_closed.isCompleted);
      _closed.complete();
    }
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
  void sendRequest(Request request) {
    // Don't send any further requests after the communication channel is
    // closed.
    if (_closeRequested) {
      return;
    }
    var jsonEncoding = json.encode(request.toJson());
    _outputLine(jsonEncoding);
    _instrumentationService.logRequest(jsonEncoding);
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
    runZonedGuarded(
      () {
        _output.writeln(s);
      },
      (e, s) {
        close();
      },
    );
  }

  /// Read a request from the given [data] and use the given function to handle
  /// the request.
  void _readRequest(String data, Sink<RequestOrResponse> sink) {
    // Ignore any further requests after the communication channel is closed.
    if (_closed.isCompleted) {
      return;
    }
    _instrumentationService.logRequest(data);
    // Parse the string as a JSON descriptor and process the resulting
    // structure as either a request or a response.
    var requestOrResponse =
        Request.fromString(data) ?? Response.fromString(data);
    if (requestOrResponse == null) {
      // If the data isn't valid, then assume it was an invalid request so that
      // clients won't be left waiting for a response.
      sendResponse(Response.invalidRequestFormat());
      return;
    }
    if (requestOrResponse is Request) {
      _requestStatistics?.addRequest(requestOrResponse);
    }
    sink.add(requestOrResponse);
  }
}

/// Instances of the class of [InputOutputByteStreamServerChannel] implement a
/// [ServerCommunicationChannel] that communicate with clients via a
/// "byte stream" and a sink.
class InputOutputByteStreamServerChannel extends ByteStreamServerChannel {
  final Stream<List<int>> _input;

  @override
  final IOSink _output;

  @override
  late final Stream<String> _lines = _input
      .transform(const Utf8Decoder())
      .transform(const LineSplitter());

  InputOutputByteStreamServerChannel(
    this._input,
    this._output,
    super._instrumentationService, {
    super.requestStatistics,
  });
}

/// Communication channel that operates via stdin/stdout.
///
/// Stdin communication is done via an isolate to speedup receiving data
/// (while we're busy performing other tasks in the main isolate), but with an
/// isolate already being used, it is used for transforming and splitting the
/// input into line strings as well.
class StdinStdoutLineStreamServerChannel extends ByteStreamServerChannel {
  @override
  final IOSink _output = stdout;
  final ReceivePort _linesFromIsolate = ReceivePort();

  @override
  late final Stream<String> _lines = _linesFromIsolate.cast();

  StdinStdoutLineStreamServerChannel(
    super._instrumentationService, {
    super.requestStatistics,
  }) {
    Isolate.spawn(_stdinInAnIsolate, _linesFromIsolate.sendPort);
  }

  static void _stdinInAnIsolate(Object message) {
    var replyTo = message as SendPort;
    stdin
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen(replyTo.send);
  }
}
