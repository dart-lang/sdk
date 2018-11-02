// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
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

@reflectiveTest
class LspAnalysisServerTest extends Object with ResourceProviderMixin {
  MockLspServerChannel channel;
  LspAnalysisServer server;

  int _id = 0;

  void setUp() {
    channel = new MockLspServerChannel();
    // Create an SDK in the mock file system.
    new MockSdk(resourceProvider: resourceProvider);
    server = new LspAnalysisServer(channel, resourceProvider);
  }

  Future tearDown() async {
    channel.close();
    await server.shutdown();
  }

  test_initialize() async {
    final result = await _initialize();
    // TODO(dantup): This test will need updating, but this is what the server
    // is currently hard-coded to claim it supports.
    expect(result.capabilities.hoverProvider, isTrue);
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

  test_unknownRequest() async {
    await _initialize();
    final request = _makeRequest('randomRequest', null);
    final response = await channel.sendRequestToServer(request);
    expect(response.id, equals(request.id));
    expect(response.error, isNotNull);
    expect(response.result, isNull);
  }

  /// A helper that initializes the server with common values, since the server
  /// will reject any other requests until it is initialized.
  Future<InitializeResult> _initialize() async {
    final request = _makeRequest(
        'initialize',
        new InitializeParams(null, null, null, null,
            new ClientCapabilities(null, null, null), null));
    final response = await channel.sendRequestToServer(request);
    expect(response.id, equals(request.id));
    expect(response.error, isNull);
    expect(response.result, isNotNull);

    final notification = _makeNotification('initialized', null);
    channel.sendNotification(notification);

    return response.result;
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
}
