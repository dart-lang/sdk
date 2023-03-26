// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_server_base.dart';
import 'constants.dart';
import 'mocks.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ServerDomainTest);
  });
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
    var responseFuture =
        server.sendOpenUriNotification(toUri('https://dart.dev'));
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
      expect(server.supportsOpenUriNotification, openUrlRequest);
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
        server.showUserPrompt(MessageType.WARNING, 'message', ['a', 'b']);
    expect(serverChannel.serverRequestsSent, hasLength(1));

    // Simulate the response.
    var request = serverChannel.serverRequestsSent[0];
    await serverChannel.simulateResponseFromClient(
        ServerShowMessageRequestResult('a').toResponse(request.id));
    var response = await responseFuture;
    expect(response, 'a');
  }

  Future<void> test_shutdown() async {
    var request = ServerShutdownParams().toRequest('0');
    await handleSuccessfulRequest(request);
  }
}
