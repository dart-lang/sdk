// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/lsp_packet_transformer.dart';
import 'package:cli_util/cli_logging.dart';
import 'package:dartdev/src/core.dart';
import 'package:dartdev/src/lsp_analysis_server.dart';
import 'package:dartdev/src/sdk.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('LspAnalysisServer', () {
    setUp(() {
      log = Logger.standard();
    });

    group('with real process', () {
      test('can start', () async {
        final p = project();

        final server = LspAnalysisServer(
          null,
          io.Directory(sdk.sdkPath),
          [p.dir],
          commandName: 'testing',
          argResults: null,
          usePlugins: false,
          suppressAnalytics: true,
        );
        await server.start();
        await server.shutdown();
      });

      test('can send a request', () async {
        final p = project(mainSrc: 'Future x;');

        final server = LspAnalysisServer(
          null,
          io.Directory(sdk.sdkPath),
          [p.dir],
          commandName: 'testing',
          argResults: null,
          usePlugins: false,
          suppressAnalytics: true,
        );
        await server.start();

        final response = await server.getHover(
          p.mainUri,
          Position(line: 0, character: 0),
        );
        final stringContent = response!.contents.map(
          (markup) => markup.value,
          (string) => string,
        );
        expect(
          stringContent,
          allOf([
            contains('class Future<T>\n'),
            contains('Declared in *dart:async*.\n'),
          ]),
        );

        await server.shutdown();
      });

      test('can receive diagnostics', () async {
        // A project with invalid code that produces 'missing_identifier'.
        final p = project(mainSrc: 'class');

        final server = LspAnalysisServer(
          null,
          io.Directory(sdk.sdkPath),
          [p.dir],
          commandName: 'testing',
          argResults: null,
          usePlugins: false,
          suppressAnalytics: true,
        );

        final diagnosticsNotifications = <PublishDiagnosticsParams>[];
        final sub = server.onErrors.listen(diagnosticsNotifications.add);

        await server.start();
        await server.workspaceAnalysisComplete();
        await sub.cancel();

        expect(diagnosticsNotifications, hasLength(1));
        final diagnosticsNotification = diagnosticsNotifications.single;
        expect(diagnosticsNotification.uri, p.mainUri);
        final diagnostics = diagnosticsNotification.diagnostics;
        expect(diagnostics, isNotEmpty);
        expect(diagnostics.map((d) => d.code), contains('missing_identifier'));

        await server.shutdown();

        await server.onExit;
        expect(server.hasCrashed, false);
      });
    });

    group('with mock process', () {
      test('handles clean shutdown', () async {
        final mockProcess = MockServerProcess();
        final server = LspAnalysisServer(
          null,
          io.Directory(sdk.sdkPath),
          [],
          commandName: 'testing',
          argResults: null,
          usePlugins: false,
          suppressAnalytics: true,
          processFactory: (_, _) async => mockProcess,
        );
        await server.start();

        server.shutdown();

        // Clean shutdown.
        await expectLater(server.onExit, completion(0));
        expect(server.hasCrashed, isFalse);
        expect(server.serverErrorReceived, isFalse);
      });

      test('treats unexpected process termination as a crash', () async {
        final mockProcess = MockServerProcess();
        final server = LspAnalysisServer(
          null,
          io.Directory(sdk.sdkPath),
          [],
          commandName: 'testing',
          argResults: null,
          usePlugins: false,
          suppressAnalytics: true,
          processFactory: (_, _) async => mockProcess,
        );
        await server.start();

        mockProcess.kill();
        await expectLater(server.onExit, completion(-1));

        expect(server.hasCrashed, isTrue);
      });

      test('records errors sent via logMessage', () async {
        final mockProcess = MockServerProcess();
        final server = LspAnalysisServer(
          null,
          io.Directory(sdk.sdkPath),
          [],
          commandName: 'testing',
          argResults: null,
          usePlugins: false,
          suppressAnalytics: true,
          processFactory: (_, _) async => mockProcess,
        );
        await server.start();

        mockProcess.sendNotification(
          Method.window_logMessage,
          LogMessageParams(message: 'Error!', type: MessageType.Error),
        );
        await pumpEventQueue();

        await server.shutdown();
        await expectLater(server.onExit, completion(0));
        expect(server.serverErrorReceived, isTrue);
        expect(server.hasCrashed, isFalse); // Was not a crash
      });

      test('records errors sent via showMessage', () async {
        final mockProcess = MockServerProcess();
        final server = LspAnalysisServer(
          null,
          io.Directory(sdk.sdkPath),
          [],
          commandName: 'testing',
          argResults: null,
          usePlugins: false,
          suppressAnalytics: true,
          processFactory: (_, _) async => mockProcess,
        );
        await server.start();

        mockProcess.sendNotification(
          Method.window_showMessage,
          ShowMessageParams(message: 'Error!', type: MessageType.Error),
        );
        await pumpEventQueue();

        await server.shutdown();
        await expectLater(server.onExit, completion(0));
        expect(server.serverErrorReceived, isTrue);
        expect(server.hasCrashed, isFalse); // Was not a crash
      });
    });
  });
}

/// A mock LSP server process used for testing things that cannot be easily
/// triggered with (or do not require) a real server.
class MockServerProcess implements io.Process {
  final exitCodeCompleter = Completer<int>();
  final stdoutStreamController = StreamController<List<int>>();
  final stderrStreamController = StreamController<List<int>>();
  final stdinStreamController = StreamController<List<int>>();

  /// A stream controller that accepts JSON packets and wraps them with
  /// LSP headers before sending to [stdout].
  final StreamController<String> lspOutput = StreamController<String>(
    sync: true,
  );

  MockServerProcess() {
    lspOutput.stream
        .transform(LspPacketEncoder())
        .listen(stdoutStreamController.add);

    stdinStreamController.stream.transform(LspPacketTransformer()).listen((
      payload,
    ) {
      final message = Message.fromJson(jsonDecode(payload));
      _handleMessage(message);
    });
  }

  void _handleRequest(RequestMessage request) {
    switch (request.method) {
      case Method.initialize:
        sendResponse(
          request,
          InitializeResult(
            capabilities: ServerCapabilities(
              experimental: {'workspaceAnalysisComplete': {}},
            ),
          ),
        );
        break;
      case Method.shutdown:
        sendResponse(
          request,
        );
        // Shutdown doesn't actually do much. The exit notification is where
        // we'd actually stop the process.
        break;
      default:
        throw 'Unexpected request to server: ${request.method}';
    }
  }

  void _handleNotification(NotificationMessage notification) {
    switch (notification.method) {
      case Method.exit:
        exitCodeCompleter.complete(0);
        break;
      case Method.initialized:
        // Nothing to do here.
        break;
      default:
        throw 'Unexpected notification to server: ${notification.method}';
    }
  }

  void _handleMessage(Message message) {
    switch (message) {
      case RequestMessage():
        _handleRequest(message);
        break;
      case NotificationMessage():
        _handleNotification(message);
        break;
      default:
        throw 'Unexpected message to server: $message';
    }
  }

  void sendResponse(RequestMessage request, [ToJsonable? result]) {
    final response = ResponseMessage(
      jsonrpc: jsonRpcVersion,
      id: request.id,
      result: result,
    );
    _sendLsp(response);
  }

  void sendNotification(Method method, LSPAny params) {
    final response = NotificationMessage(
      jsonrpc: jsonRpcVersion,
      method: method,
      params: params,
    );
    _sendLsp(response);
  }

  void _sendLsp(Message message) {
    final json = jsonEncode(message.toJson());
    lspOutput.add(json);
  }

  @override
  late final stdin = io.IOSink(stdinStreamController);

  @override
  Future<int> get exitCode => exitCodeCompleter.future;

  @override
  bool kill([io.ProcessSignal signal = io.ProcessSignal.sigterm]) {
    if (!exitCodeCompleter.isCompleted) {
      exitCodeCompleter.complete(-1);
      return true;
    }
    return false;
  }

  @override
  int get pid => 123;

  @override
  Stream<List<int>> get stderr => stderrStreamController.stream;

  @override
  Stream<List<int>> get stdout => stdoutStreamController.stream;
}
