// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:analyzer/src/test_utilities/mock_sdk.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../mocks.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LspAnalysisServerTest);
  });
}

const dartLanguageId = 'dart';

/// Useful for debugging locally, setting this to true will cause all JSON
/// communication to be printed to stdout.
const debugPrintCommunication = false;

@reflectiveTest
class LspAnalysisServerTest extends Object with ResourceProviderMixin {
  MockLspServerChannel channel;
  LspAnalysisServer server;

  int _id = 0;
  String projectFolderPath, mainFilePath;
  Uri mainFileUri;

  void setUp() {
    channel = new MockLspServerChannel(debugPrintCommunication);
    // Create an SDK in the mock file system.
    new MockSdk(resourceProvider: resourceProvider);
    server = new LspAnalysisServer(
        channel,
        resourceProvider,
        new AnalysisServerOptions(),
        new DartSdkManager(convertPath('/sdk'), false),
        InstrumentationService.NULL_SERVICE);

    projectFolderPath = convertPath('/project');
    newFolder(projectFolderPath);
    newFolder(join(projectFolderPath, 'lib'));
    mainFilePath = join(projectFolderPath, 'lib', 'main.dart');
    mainFileUri = Uri.file(mainFilePath);
  }

  Future tearDown() async {
    channel.close();
    await server.shutdown();
  }

  test_diagnostics_after_document_changes() async {
    const initialContents = 'int a = 1;';
    newFile(mainFilePath, content: initialContents);

    await _initialize();
    final initialDiagnostics = await _waitForDiagnostics(mainFileUri);
    expect(initialDiagnostics, hasLength(0));

    await _openFile(mainFileUri, initialContents);
    await _replaceFile(mainFileUri, 'String a = 1;');
    final updatedDiagnostics = await _waitForDiagnostics(mainFileUri);
    expect(updatedDiagnostics, hasLength(1));
  }

  test_diagnostics_notifications() async {
    newFile(mainFilePath, content: 'String a = 1;');

    await _initialize();
    final diagnostics = await _waitForDiagnostics(mainFileUri);
    expect(diagnostics, hasLength(1));
    final diagnostic = diagnostics.first;
    expect(diagnostic.code.valueEquals('invalid_assignment'), isTrue);
    expect(diagnostic.range.start.line, equals(0));
    expect(diagnostic.range.start.character, equals(11));
    expect(diagnostic.range.end.line, equals(0));
    expect(diagnostic.range.end.character, equals(12));
  }

  test_document_change_partial() async {
    final initialContent = '0123456789\n0123456789';
    final expectedUpdatedContent = '0123456789\n01234   89';

    await _initialize();
    await _openFile(mainFileUri, initialContent);
    await _changeFile(mainFileUri, [
      // Replace line1:5-1:8 with spaces.
      new TextDocumentContentChangeEvent(
        new Range(new Position(1, 5), new Position(1, 8)),
        null,
        '   ',
      )
    ]);
    expect(server.fileContentOverlay[mainFilePath],
        equals(expectedUpdatedContent));
  }

  test_document_change_replace() async {
    final initialContent = 'int a = 1;';
    final updatedContent = 'int a = 2;';

    await _initialize();
    await _openFile(mainFileUri, initialContent);
    await _replaceFile(mainFileUri, updatedContent);
    expect(server.fileContentOverlay[mainFilePath], equals(updatedContent));
  }

  test_document_close() async {
    final initialContent = 'int a = 1;';
    final updatedContent = 'int a = 2;';

    await _initialize();
    await _openFile(mainFileUri, initialContent);
    await _replaceFile(mainFileUri, updatedContent);
    await _closeFile(mainFileUri);
    expect(server.fileContentOverlay[mainFilePath], isNull);
  }

  test_document_open() async {
    const testContent = 'CONTENT';

    await _initialize();
    expect(server.fileContentOverlay[mainFilePath], isNull);
    await _openFile(mainFileUri, testContent);
    expect(server.fileContentOverlay[mainFilePath], equals(testContent));
  }

  test_initialize() async {
    final response = await _initialize();
    expect(response, isNotNull);
    expect(response.error, isNull);
    expect(response.result, isNotNull);
    expect(response.result, TypeMatcher<InitializeResult>());
    InitializeResult result = response.result;
    expect(result.capabilities, isNotNull);
    // Check some basic capabilities that are unlikely to change.
    expect(result.capabilities.textDocumentSync, isNotNull);
    result.capabilities.textDocumentSync.map(
      (options) {
        // We'll always request open/closed notifications and incremental updates.
        expect(options.openClose, isTrue);
        expect(options.change, equals(TextDocumentSyncKind.Incremental));
      },
      (_) =>
          throw 'Expected textDocumentSync capabilities to be a $TextDocumentSyncOptions',
    );
  }

  test_initialize_cannot_be_called_twice() async {
    await _initialize();
    final response = await _initialize();
    expect(response, isNotNull);
    expect(response.result, isNull);
    expect(response.error, isNotNull);
    expect(
        response.error.code, equals(ServerErrorCodes.ServerAlreadyInitialized));
  }

  test_requests_before_initialize_are_rejected_and_logged() async {
    final request = _makeRequest('randomRequest', null);
    final nextNotification = channel.waitForNotificationFromServer();
    final response = await channel.sendRequestToServer(request);
    expect(response.id, equals(request.id));
    expect(response.result, isNull);
    expect(response.error, isNotNull);
    expect(response.error.code, ErrorCodes.ServerNotInitialized);
    final notification = await nextNotification;
    expect(notification.method, equals('window/logMessage'));
    LogMessageParams logParams = notification.params.map(
      (_) => throw 'Expected dynamic, got List<dynamic>',
      (params) => params,
    );
    expect(logParams.type, equals(MessageType.Error));
  }

  @failingTest
  test_shutdown() async {
    await _initialize();
    final request = _makeRequest('shutdown', null);
    final response = await channel.sendRequestToServer(request);
    expect(response.id, equals(request.id));
    expect(response.error, isNull);
    expect(response.result, isNull);
  }

  test_unknown_request() async {
    await _initialize();
    final request = _makeRequest('randomRequest', null);
    final response = await channel.sendRequestToServer(request);
    expect(response.id, equals(request.id));
    expect(response.error, isNotNull);
    expect(response.result, isNull);
  }

  Future _changeFile(
      Uri uri, List<TextDocumentContentChangeEvent> changes) async {
    var notification = _makeNotification(
      'textDocument/didChange',
      new DidChangeTextDocumentParams(
          new VersionedTextDocumentIdentifier(1, uri.toString()), changes),
    );
    channel.sendNotificationToServer(notification);
    await pumpEventQueue();
  }

  Future _closeFile(Uri uri) async {
    var notification = _makeNotification(
      'textDocument/didClose',
      new DidCloseTextDocumentParams(
          new TextDocumentIdentifier(uri.toString())),
    );
    channel.sendNotificationToServer(notification);
    await pumpEventQueue();
  }

  /// A helper that initializes the server with common values, since the server
  /// will reject any other requests until it is initialized.
  Future<ResponseMessage> _initialize([String rootPath]) async {
    final rootUri = Uri.file(rootPath ?? projectFolderPath).toString();
    final request = _makeRequest(
        'initialize',
        new InitializeParams(null, null, rootUri, null,
            new ClientCapabilities(null, null, null), null));
    final response = await channel.sendRequestToServer(request);
    expect(response.id, equals(request.id));

    if (response.error == null) {
      final notification = _makeNotification('initialized', null);
      channel.sendNotificationToServer(notification);
    }

    return response;
  }

  NotificationMessage _makeNotification(String method, ToJsonable params) {
    return new NotificationMessage(
        method, Either2<List<dynamic>, dynamic>.t2(params), '2.0');
  }

  RequestMessage _makeRequest(String method, ToJsonable params) {
    final id = Either2<num, String>.t1(_id++);
    return new RequestMessage(
        id, method, Either2<List<dynamic>, dynamic>.t2(params), '2.0');
  }

  Future _openFile(Uri uri, String content) async {
    var notification = _makeNotification(
      'textDocument/didOpen',
      new DidOpenTextDocumentParams(
          new TextDocumentItem(uri.toString(), dartLanguageId, 1, content)),
    );
    channel.sendNotificationToServer(notification);
    await pumpEventQueue();
  }

  Future _replaceFile(Uri uri, String content) async {
    await _changeFile(
      uri,
      [new TextDocumentContentChangeEvent(null, null, content)],
    );
  }

  Future<List<Diagnostic>> _waitForDiagnostics(Uri uri) async {
    PublishDiagnosticsParams diagnosticParams;
    await channel.serverToClient.firstWhere((message) {
      if (message is NotificationMessage &&
          message.method == 'textDocument/publishDiagnostics') {
        // TODO(dantup): Make a better way to extract params without copying
        // this map into all places. Although the spec says the `params` field
        // for `NotificationMessage` is `Array<any> | Object` it also says that
        // for `textDocument/publishDiagnostics` it is `PublishDiagnosticsParams`.
        diagnosticParams = message.params.map(
          (_) => throw 'Expected dynamic, got List<dynamic>',
          (params) => params,
        );

        return diagnosticParams.uri == uri.toString();
      }
      return false;
    });
    return diagnosticParams.diagnostics;
  }
}
