// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/src/analytics/analytics_manager.dart'
    show AnalyticsManager;
import 'package:analysis_server/src/legacy_analysis_server.dart' as a;
import 'package:analysis_server/src/lsp/channel/lsp_channel.dart'
    show LspServerCommunicationChannel;
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart' as lsp;
import 'package:analysis_server/src/server/crash_reporting_attachments.dart'
    show CrashReportingAttachmentsBuilder;
import 'package:analysis_server/src/session_logger/session_logger.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:dartpad/src/dartpad_config.dart';
import 'package:unified_analytics/unified_analytics.dart' show NoOpAnalytics;

class LanguageServer {
  late final lsp.LspAnalysisServer _server;

  final _closed = Completer<void>();
  final _input = StreamController<Map<String, Object?>>();
  final _output = StreamController<Map<String, Object?>>();

  LanguageServer({
    required ResourceProvider resourceProvider,
    required DartPadConfig config,
  }) {
    _server = lsp.LspAnalysisServer(
      _LspServerCommunicationChannel(_input.stream, _output.sink),
      resourceProvider,
      a.AnalysisServerOptions(),
      DartSdkManager(config.dartSdkPath),
      AnalyticsManager(const NoOpAnalytics()),
      CrashReportingAttachmentsBuilder.empty,
      InstrumentationService.NULL_SERVICE,
      SessionLogger(),
      httpClient: null,
      processRunner: null,
      diagnosticServer: null,
      detachableFileSystemManager: null,
    );
    _server.exited.whenComplete(() {
      if (!_closed.isCompleted) {
        _closed.complete();
      }
      _output.sink.close();
    });
  }

  Future<void> close() async {
    await _input.sink.close();
    await _server.shutdown();
    if (!_closed.isCompleted) {
      _closed.complete();
    }
  }

  Future<void> get closed => _closed.future;

  Stream<Map<String, Object?>> get messages => _output.stream;

  Future<void> handle(Map<String, Object?> m) async => _input.add(m);
}

final class _LspServerCommunicationChannel
    extends LspServerCommunicationChannel {
  final Stream<Map<String, Object?>> _input;
  final StreamSink<Map<String, Object?>> _output;
  final _closed = Completer<void>();
  var _closing = false;

  _LspServerCommunicationChannel(this._input, this._output);

  @override
  Future<void> close() async {
    if (!_closing) {
      _closing = true;
      await _output.close();
    }
  }

  @override
  Future<void> get closed => _closed.future;

  @override
  StreamSubscription<void> listen(
    void Function(lsp.Message message) onMessage, {
    Function? onError,
    void Function()? onDone,
  }) {
    return _input.listen(
      (m) => onMessage(lsp.Message.fromJson(m)),
      onError: onError,
      onDone: () {
        _closed.complete();
        if (onDone != null) {
          onDone();
        }
      },
    );
  }

  void _send(lsp.Message m) {
    if (_closing) {
      return;
    }
    _output.add(m.toJson());
  }

  @override
  void sendNotification(lsp.NotificationMessage m) => _send(m);

  @override
  void sendRequest(lsp.RequestMessage m) => _send(m);

  @override
  void sendResponse(lsp.ResponseMessage m) => _send(m);
}
