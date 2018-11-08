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

import '../mocks.dart';

const dartLanguageId = 'dart';

/// Useful for debugging locally, setting this to true will cause all JSON
/// communication to be printed to stdout.
const debugPrintCommunication = false;

abstract class AbstractLspAnalysisServerTest extends Object
    with ResourceProviderMixin {
  MockLspServerChannel channel;
  LspAnalysisServer server;

  int _id = 0;
  String projectFolderPath, mainFilePath;
  Uri mainFileUri;

  Future changeFile(
      Uri uri, List<TextDocumentContentChangeEvent> changes) async {
    var notification = makeNotification(
      'textDocument/didChange',
      new DidChangeTextDocumentParams(
          new VersionedTextDocumentIdentifier(1, uri.toString()), changes),
    );
    channel.sendNotificationToServer(notification);
    await pumpEventQueue();
  }

  Future closeFile(Uri uri) async {
    var notification = makeNotification(
      'textDocument/didClose',
      new DidCloseTextDocumentParams(
          new TextDocumentIdentifier(uri.toString())),
    );
    channel.sendNotificationToServer(notification);
    await pumpEventQueue();
  }

  /// A helper that initializes the server with common values, since the server
  /// will reject any other requests until it is initialized.
  Future<ResponseMessage> initialize([String rootPath]) async {
    final rootUri = Uri.file(rootPath ?? projectFolderPath).toString();
    final request = makeRequest(
        'initialize',
        new InitializeParams(null, null, rootUri, null,
            new ClientCapabilities(null, null, null), null, null));
    final response = await channel.sendRequestToServer(request);
    expect(response.id, equals(request.id));

    if (response.error == null) {
      final notification = makeNotification('initialized', null);
      channel.sendNotificationToServer(notification);
    }

    return response;
  }

  NotificationMessage makeNotification(String method, ToJsonable params) {
    return new NotificationMessage(
        method, Either2<List<dynamic>, dynamic>.t2(params), '2.0');
  }

  RequestMessage makeRequest(String method, ToJsonable params) {
    final id = Either2<num, String>.t1(_id++);
    return new RequestMessage(
        id, method, Either2<List<dynamic>, dynamic>.t2(params), '2.0');
  }

  Future openFile(Uri uri, String content) async {
    var notification = makeNotification(
      'textDocument/didOpen',
      new DidOpenTextDocumentParams(
          new TextDocumentItem(uri.toString(), dartLanguageId, 1, content)),
    );
    channel.sendNotificationToServer(notification);
    await pumpEventQueue();
  }

  Future replaceFile(Uri uri, String content) async {
    await changeFile(
      uri,
      [new TextDocumentContentChangeEvent(null, null, content)],
    );
  }

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

  Future<List<Diagnostic>> waitForDiagnostics(Uri uri) async {
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
