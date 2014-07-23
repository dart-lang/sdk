// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.socket.server;

import 'dart:async';

import 'mocks.dart';

import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:analyzer/src/generated/sdk_io.dart';
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
    SocketServer server = new SocketServer(DirectoryBasedDartSdk.defaultSdk);
    MockServerChannel channel = new MockServerChannel();
    server.createAnalysisServer(channel);
    channel.expectMsgCount(notificationCount: 1);
    expect(channel.notificationsReceived[0].event, SERVER_CONNECTED);
    expect(channel.notificationsReceived[0].params, isEmpty);
    return channel.sendRequest(
        new Request('0', SERVER_SHUTDOWN)
    ).then((Response response) {
      expect(response.id, equals('0'));
      expect(response.error, isNull);
      channel.expectMsgCount(responseCount: 1, notificationCount: 1);
    });
  }

  static void createAnalysisServer_alreadyStarted() {
    SocketServer server = new SocketServer(DirectoryBasedDartSdk.defaultSdk);
    MockServerChannel channel1 = new MockServerChannel();
    MockServerChannel channel2 = new MockServerChannel();
    server.createAnalysisServer(channel1);
    expect(channel1.notificationsReceived[0].event, SERVER_CONNECTED);
    expect(channel1.notificationsReceived[0].params, isEmpty);
    server.createAnalysisServer(channel2);
    channel1.expectMsgCount(notificationCount: 1);
    channel2.expectMsgCount(responseCount: 1);
    expect(channel2.responsesReceived[0].id, equals(''));
    expect(channel2.responsesReceived[0].error, isNotNull);
    expect(channel2.responsesReceived[0].error.code, equals(
        RequestError.CODE_SERVER_ALREADY_STARTED));
    channel2.sendRequest(new Request('0', SERVER_SHUTDOWN)).then((Response response) {
      expect(response.id, equals('0'));
      expect(response.error, isNotNull);
      expect(response.error.code, equals(
          RequestError.CODE_SERVER_ALREADY_STARTED));
      channel2.expectMsgCount(responseCount: 2);
    });
  }
}
