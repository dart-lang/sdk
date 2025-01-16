// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart'
    hide MessageType;
import 'package:analysis_server/src/analysis_server.dart' show MessageType;
import 'package:analysis_server/src/services/user_prompts/dart_fix_prompt_manager.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_server_base.dart';
import 'constants.dart';
import 'mocks.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ServerDomainTest);
    defineReflectiveTests(ServerDartFixPromptTest);
  });
}

/// Checks server interacts with [DartFixPromptManager] correctly.
///
/// Tests for [DartFixPromptManager]'s behaviour are in
/// test/services/user_prompts/dart_fix_prompt_manager_test.dart.
@reflectiveTest
class ServerDartFixPromptTest extends PubPackageAnalysisServerTest {
  late TestDartFixPromptManager promptManager;

  @override
  DartFixPromptManager? get dartFixPromptManager => promptManager;

  @override
  void setUp() {
    promptManager = TestDartFixPromptManager();
    super.setUp();
  }

  Future<void> test_trigger_afterInitialAnalysis() async {
    await setRoots(included: [workspaceRootPath], excluded: []);
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksTriggered, 1);
  }

  Future<void> test_trigger_afterPackageConfigChange() async {
    // Ensure there's a file to analyze otherwise writing the package_config
    // won't trigger any additional analysis.
    newFile('$testPackageLibPath/test.dart', 'void f() {}');

    // Set up and let initial analysis complete.
    await setRoots(included: [workspaceRootPath], excluded: []);
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksTriggered, 1);

    // Expect that writing package config attempts to trigger another check.
    writeTestPackageConfig();
    await pumpEventQueue(times: 5000);
    expect(promptManager.checksTriggered, 2);
  }
}

@reflectiveTest
class ServerDomainTest extends PubPackageAnalysisServerTest {
  Future<void> test_getVersion() async {
    var request = ServerGetVersionParams().toRequest(
      '0',
      clientUriConverter: server.uriConverter,
    );
    var response = await handleSuccessfulRequest(request);
    expect(
      response.toJson(),
      equals({
        Response.ID: '0',
        Response.RESULT: {VERSION: PROTOCOL_VERSION},
      }),
    );
  }

  Future<void> test_openUrl() async {
    server.clientCapabilities.requests = ['openUrlRequest'];

    // Send the request.
    var uri = toUri('https://dart.dev');
    var responseFuture = server.openUriNotificationSender!.call(uri);
    expect(serverChannel.serverRequestsSent, hasLength(1));

    // Simulate the response.
    var request = serverChannel.serverRequestsSent[0];
    await serverChannel.simulateResponseFromClient(
      ServerOpenUrlRequestResult().toResponse(
        request.id,
        clientUriConverter: server.uriConverter,
      ),
    );
    await responseFuture;
  }

  Future<void> test_setClientCapabilities_lspCapabilities() async {
    // Test an arbitrary set of capabilities.
    var capabilities = lsp.ClientCapabilities(
      textDocument: lsp.TextDocumentClientCapabilities(
        hover: lsp.HoverClientCapabilities(
          contentFormat: [lsp.MarkupKind.PlainText],
        ),
      ),
      workspace: lsp.WorkspaceClientCapabilities(
        applyEdit: true,
        workspaceEdit: lsp.WorkspaceEditClientCapabilities(
          documentChanges: true,
          resourceOperations: [lsp.ResourceOperationKind.Create],
        ),
      ),
    );

    var request = ServerSetClientCapabilitiesParams(
      [],
      lspCapabilities: capabilities.toJson(),
    ).toRequest('1', clientUriConverter: server.uriConverter);

    await handleSuccessfulRequest(request);
    var effectiveCapabilities = server.editorClientCapabilities;
    expect(
      effectiveCapabilities.hoverContentFormats,
      equals([lsp.MarkupKind.PlainText]),
    );
    expect(effectiveCapabilities.applyEdit, isTrue);
    expect(effectiveCapabilities.documentChanges, isTrue);
    expect(effectiveCapabilities.createResourceOperations, isTrue);
  }

  Future<void> test_setClientCapabilities_lspCapabilities_invalid() async {
    var request = ServerSetClientCapabilitiesParams(
      [],
      lspCapabilities: {
        'textDocument': 1, // Not valid
      },
    ).toRequest('1', clientUriConverter: server.uriConverter);

    var response = await handleRequest(request);
    expect(
      response,
      isResponseFailure('1', RequestErrorCode.INVALID_PARAMETER),
    );
    expect(
      response.error!.message,
      "The 'lspCapabilities' parameter was invalid:"
      ' textDocument must be of type TextDocumentClientCapabilities',
    );
  }

  Future<void> test_setClientCapabilities_requests() async {
    var requestId = -1;

    Future<void> setCapabilities({
      required bool openUrlRequest,
      required bool showMessageRequest,
    }) async {
      var requests = [
        if (openUrlRequest) 'openUrlRequest',
        if (showMessageRequest) 'showMessageRequest',
      ];
      if (requestId >= 0) {
        // This is a bit of a kludge, but the first time this function is called
        // we won't set the request, we'll just test the default state.
        var request = ServerSetClientCapabilitiesParams(requests).toRequest(
          requestId.toString(),
          clientUriConverter: server.uriConverter,
        );
        await handleSuccessfulRequest(request);
      }
      requestId++;

      expect(server.clientCapabilities.requests, requests);
      expect(
        server.openUriNotificationSender,
        openUrlRequest ? isNotNull : isNull,
      );
      expect(server.userPromptSender, showMessageRequest ? isNotNull : isNull);
    }

    await setCapabilities(openUrlRequest: false, showMessageRequest: false);
    await setCapabilities(openUrlRequest: true, showMessageRequest: false);
    await setCapabilities(openUrlRequest: true, showMessageRequest: true);
    await setCapabilities(openUrlRequest: false, showMessageRequest: true);
    await setCapabilities(openUrlRequest: false, showMessageRequest: false);
  }

  /// Verify that the server handles URIs once we've enabled the supportsUris
  /// client capability.
  Future<void>
  test_setClientCapabilities_supportsUris_clientToServer_request() async {
    // Tell the server we support URIs.
    await handleSuccessfulRequest(
      ServerSetClientCapabilitiesParams(
        [],
        supportsUris: true,
      ).toRequest('-1', clientUriConverter: server.uriConverter),
    );

    // Set the roots using a URI. Since the helper methods will to through
    // toJson() (which will convert paths to URIs) we need to pass the JSON
    // manually here.
    await handleSuccessfulRequest(
      Request('1', 'analysis.setAnalysisRoots', {
        'included': [toUri(workspaceRootPath).toString()],
        'excluded': [],
      }),
    );
    await pumpEventQueue(times: 5000);

    // Ensure the roots were recorded correctly.
    expect(server.contextManager.includedPaths, [
      convertPath(workspaceRootPath),
    ]);
  }

  Future<void> test_setClientCapabilities_supportsUris_defaults() async {
    // Before request.
    expect(server.clientCapabilities.supportsUris, isNull);
    expect(server.uriConverter.supportedNonFileSchemes, isEmpty);

    // If not supplied.
    await handleSuccessfulRequest(
      ServerSetClientCapabilitiesParams(
        [],
      ).toRequest('-1', clientUriConverter: server.uriConverter),
    );
    expect(server.clientCapabilities.supportsUris, isNull);
    expect(server.uriConverter.supportedNonFileSchemes, isEmpty);

    // If set explicitly to false.
    await handleSuccessfulRequest(
      ServerSetClientCapabilitiesParams(
        [],
        supportsUris: false,
      ).toRequest('-1', clientUriConverter: server.uriConverter),
    );
    expect(server.clientCapabilities.supportsUris, isFalse);
    expect(server.uriConverter.supportedNonFileSchemes, isEmpty);
  }

  Future<void>
  test_setClientCapabilities_supportsUris_false_rejectsUris() async {
    // Explicitly tell the server we do not support URIs.
    await handleSuccessfulRequest(
      ServerSetClientCapabilitiesParams(
        [],
        supportsUris: false,
      ).toRequest('-1', clientUriConverter: server.uriConverter),
    );

    // Try to send a URI anyway.
    var request = Request('1', 'analysis.setAnalysisRoots', {
      'included': [toUri(workspaceRootPath).toString()],
      'excluded': [],
    });
    var response = await handleRequest(request);
    expect(
      response,
      isResponseFailure(request.id, RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  /// Verify that the server uses URIs in notifications once we've enabled the
  /// supportsUris client capability.
  Future<void>
  test_setClientCapabilities_supportsUris_serverToClient_notification() async {
    // Add a file with an error for testing.
    var testFilePath = convertPath('$testPackageLibPath/test.dart');
    var testFileUriString = toUri(testFilePath).toString();
    newFile(testFilePath, 'broken');

    // Tell the server we support URIs before analysis starts since we will
    // verify the analysis.errors notification.
    await handleSuccessfulRequest(
      ServerSetClientCapabilitiesParams(
        [],
        supportsUris: true,
      ).toRequest('10', clientUriConverter: server.uriConverter),
    );
    await pumpEventQueue(times: 5000);

    // Trigger analysis.
    await setRoots(
      // We can use paths here because toJson() will handle the conversion.
      included: [workspaceRootPath],
      excluded: [],
    );
    await pumpEventQueue(times: 5000);

    // Verify the last error for this file was using a URI.
    var lastErrorFile = serverChannel.notificationsReceived
        .where((notification) => notification.event == 'analysis.errors')
        .map((notification) => notification.params!['file'] as String)
        .lastWhere((filePath) => filePath.endsWith('test.dart'));
    expect(lastErrorFile, testFileUriString);
  }

  /// Verify that the server returns URIs once we've enabled the supportsUris
  /// client capability.
  Future<void>
  test_setClientCapabilities_supportsUris_serverToClient_response() async {
    // Add a file with an error for testing.
    var testFilePath = convertPath('$testPackageLibPath/test.dart');
    var testFileUriString = toUri(testFilePath).toString();
    newFile(testFilePath, 'broken');

    await setRoots(included: [workspaceRootPath], excluded: []);
    await pumpEventQueue(times: 5000);

    // Tell the server we support URIs.
    await handleSuccessfulRequest(
      ServerSetClientCapabilitiesParams(
        [],
        supportsUris: true,
      ).toRequest('10', clientUriConverter: server.uriConverter),
    );
    await pumpEventQueue(times: 5000);

    // Send a GetErrors request. The response has nested FilePaths inside the
    // AnalysisErrors so will confirm the server mapped correctly.
    var response = await handleSuccessfulRequest(
      Request('1', 'analysis.getErrors', {'file': testFileUriString}),
    );
    // Verify the error location was the expected URI.
    expect(
      (response.result as dynamic)['errors'][0]!['location']['file'],
      testFileUriString,
    );
  }

  Future<void>
  test_setClientCapabilities_supportsUris_unspecified_rejectsUris() async {
    // Do not tell the server we support URIs.

    // Try to send a URI anyway.
    var request = Request('1', 'analysis.setAnalysisRoots', {
      'included': [toUri(workspaceRootPath).toString()],
      'excluded': [],
    });
    var response = await handleRequest(request);
    expect(
      response,
      isResponseFailure(request.id, RequestErrorCode.INVALID_FILE_PATH_FORMAT),
    );
  }

  Future<void> test_setSubscriptions_invalidServiceName() async {
    var request = Request('0', SERVER_REQUEST_SET_SUBSCRIPTIONS, {
      SUBSCRIPTIONS: ['noSuchService'],
    });
    var response = await handleRequest(request);
    expect(response, isResponseFailure('0'));
  }

  Future<void> test_setSubscriptions_success() async {
    expect(server.serverServices, isEmpty);
    // send request
    var request = ServerSetSubscriptionsParams([
      ServerService.STATUS,
    ]).toRequest('0', clientUriConverter: server.uriConverter);
    await handleSuccessfulRequest(request);
    // set of services has been changed
    expect(server.serverServices, contains(ServerService.STATUS));
  }

  Future<void> test_showMessage() async {
    server.clientCapabilities.requests = ['showMessageRequest'];

    // Send the request.
    var responseFuture = server.userPromptSender!(
      MessageType.warning,
      'message',
      ['a', 'b'],
    );
    expect(serverChannel.serverRequestsSent, hasLength(1));

    // Simulate the response.
    var request = serverChannel.serverRequestsSent[0];
    await serverChannel.simulateResponseFromClient(
      ServerShowMessageRequestResult(
        action: 'a',
      ).toResponse(request.id, clientUriConverter: server.uriConverter),
    );
    var response = await responseFuture;
    expect(response, 'a');
  }

  Future<void> test_showMessage_nullResponse() async {
    server.clientCapabilities.requests = ['showMessageRequest'];

    // Send the request.
    var responseFuture = server.userPromptSender!(
      MessageType.warning,
      'message',
      ['a', 'b'],
    );
    expect(serverChannel.serverRequestsSent, hasLength(1));

    // Simulate the response.
    var request = serverChannel.serverRequestsSent[0];
    await serverChannel.simulateResponseFromClient(
      ServerShowMessageRequestResult().toResponse(
        request.id,
        clientUriConverter: server.uriConverter,
      ),
    );
    var response = await responseFuture;
    expect(response, isNull);
  }

  Future<void> test_shutdown() async {
    var request = ServerShutdownParams().toRequest(
      '0',
      clientUriConverter: server.uriConverter,
    );
    await handleSuccessfulRequest(request);
  }
}

class TestDartFixPromptManager implements DartFixPromptManager {
  var checksTriggered = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  void triggerCheck() {
    checksTriggered++;
  }
}
