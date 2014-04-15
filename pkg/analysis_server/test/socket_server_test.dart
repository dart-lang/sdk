// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.socket.server;

import 'dart:async';

import 'mocks.dart';

import 'package:analysis_server/src/domain_server.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:unittest/unittest.dart';

main() {
  group('SocketServer', () {
    test('createAnalysisServer_successful',
        SocketServerTest.createAnalysisServer_successful);
    test('createAnalysisServer_alreadyStarted',
        SocketServerTest.createAnalysisServer_alreadyStarted);
  });
}

class SocketServerTest {
  static Future createAnalysisServer_successful() {
    SocketServer server = new SocketServer();
    MockServerChannel channel = new MockServerChannel();
    server.createAnalysisServer(channel);
    channel.expectMsgCount(responseCount: 0);
    return channel.sendRequest(new Request('0',
        ServerDomainHandler.SHUTDOWN_METHOD)).then((Response response) {
      expect(response.id, equals('0'));
      expect(response.error, isNull);
      channel.expectMsgCount(responseCount: 1);
    });
  }

  static void createAnalysisServer_alreadyStarted() {
    SocketServer server = new SocketServer();
    MockServerChannel channel1 = new MockServerChannel();
    MockServerChannel channel2 = new MockServerChannel();
    server.createAnalysisServer(channel1);
    server.createAnalysisServer(channel2);
    channel1.expectMsgCount(responseCount: 0);
    channel2.expectMsgCount(responseCount: 1);
    expect(channel2.responsesReceived[0].id, equals(''));
    expect(channel2.responsesReceived[0].error, isNotNull);
    expect(channel2.responsesReceived[0].error.code, equals(
        RequestError.CODE_SERVER_ALREADY_STARTED));
    channel2.sendRequest(new Request('0', ServerDomainHandler.SHUTDOWN_METHOD)
        ).then((Response response) {
      expect(response.id, equals('0'));
      expect(response.error, isNotNull);
      expect(response.error.code, equals(
          RequestError.CODE_SERVER_ALREADY_STARTED));
      channel2.expectMsgCount(responseCount: 2);
    });
  }
}
