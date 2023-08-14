// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

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
    var request = ServerGetVersionParams().toRequest('0');
    var response = await handleSuccessfulRequest(request);
    expect(
        response.toJson(),
        equals({
          Response.ID: '0',
          Response.RESULT: {VERSION: PROTOCOL_VERSION}
        }));
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
        ServerOpenUrlRequestResult().toResponse(request.id));
    await responseFuture;
  }

  Future<void> test_setClientCapabilities() async {
    var requestId = -1;

    Future<void> setCapabilities(
        {required bool openUrlRequest,
        required bool showMessageRequest}) async {
      var requests = [
        if (openUrlRequest) 'openUrlRequest',
        if (showMessageRequest) 'showMessageRequest',
      ];
      if (requestId >= 0) {
        // This is a bit of a kludge, but the first time this function is called
        // we won't set the request, we'll just test the default state.
        var request = ServerSetClientCapabilitiesParams(requests)
            .toRequest(requestId.toString());
        await handleSuccessfulRequest(request);
      }
      requestId++;

      expect(server.clientCapabilities.requests, requests);
      expect(server.openUriNotificationSender,
          openUrlRequest ? isNotNull : isNull);
      expect(server.supportsShowMessageRequest, showMessageRequest);
    }

    await setCapabilities(openUrlRequest: false, showMessageRequest: false);
    await setCapabilities(openUrlRequest: true, showMessageRequest: false);
    await setCapabilities(openUrlRequest: true, showMessageRequest: true);
    await setCapabilities(openUrlRequest: false, showMessageRequest: true);
    await setCapabilities(openUrlRequest: false, showMessageRequest: false);
  }

  Future<void> test_setSubscriptions_invalidServiceName() async {
    var request = Request('0', SERVER_REQUEST_SET_SUBSCRIPTIONS, {
      SUBSCRIPTIONS: ['noSuchService']
    });
    var response = await handleRequest(request);
    expect(response, isResponseFailure('0'));
  }

  Future<void> test_setSubscriptions_success() async {
    expect(server.serverServices, isEmpty);
    // send request
    var request =
        ServerSetSubscriptionsParams([ServerService.STATUS]).toRequest('0');
    await handleSuccessfulRequest(request);
    // set of services has been changed
    expect(server.serverServices, contains(ServerService.STATUS));
  }

  Future<void> test_showMessage() async {
    server.clientCapabilities.requests = ['showMessageRequest'];

    // Send the request.
    var responseFuture =
        server.showUserPrompt(MessageType.warning, 'message', ['a', 'b']);
    expect(serverChannel.serverRequestsSent, hasLength(1));

    // Simulate the response.
    var request = serverChannel.serverRequestsSent[0];
    await serverChannel.simulateResponseFromClient(
        ServerShowMessageRequestResult(action: 'a').toResponse(request.id));
    var response = await responseFuture;
    expect(response, 'a');
  }

  Future<void> test_showMessage_nullResponse() async {
    server.clientCapabilities.requests = ['showMessageRequest'];

    // Send the request.
    var responseFuture =
        server.showUserPrompt(MessageType.warning, 'message', ['a', 'b']);
    expect(serverChannel.serverRequestsSent, hasLength(1));

    // Simulate the response.
    var request = serverChannel.serverRequestsSent[0];
    await serverChannel.simulateResponseFromClient(
        ServerShowMessageRequestResult().toResponse(request.id));
    var response = await responseFuture;
    expect(response, isNull);
  }

  Future<void> test_shutdown() async {
    var request = ServerShutdownParams().toRequest('0');
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
