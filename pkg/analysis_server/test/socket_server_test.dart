// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.socket.server;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/plugin/server_plugin.dart';
import 'package:analysis_server/src/socket_server.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:analyzer/src/dart/sdk/sdk.dart';
import 'package:analyzer/src/generated/sdk.dart';
import 'package:plugin/manager.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';
import 'utils.dart';

main() {
  initializeTestEnvironment();
  group('SocketServer', () {
    test('createAnalysisServer_successful',
        SocketServerTest.createAnalysisServer_successful);
    test('createAnalysisServer_alreadyStarted',
        SocketServerTest.createAnalysisServer_alreadyStarted);
    test('requestHandler_exception', SocketServerTest.requestHandler_exception);
    test('requestHandler_futureException',
        SocketServerTest.requestHandler_futureException);
  });
}

class SocketServerTest {
  static void createAnalysisServer_alreadyStarted() {
    SocketServer server = _createSocketServer();
    MockServerChannel channel1 = new MockServerChannel();
    MockServerChannel channel2 = new MockServerChannel();
    server.createAnalysisServer(channel1);
    expect(channel1.notificationsReceived[0].event, SERVER_CONNECTED);
    server.createAnalysisServer(channel2);
    channel1.expectMsgCount(notificationCount: 1);
    channel2.expectMsgCount(responseCount: 1);
    expect(channel2.responsesReceived[0].id, equals(''));
    expect(channel2.responsesReceived[0].error, isNotNull);
    expect(channel2.responsesReceived[0].error.code,
        equals(RequestErrorCode.SERVER_ALREADY_STARTED));
    channel2
        .sendRequest(new ServerShutdownParams().toRequest('0'))
        .then((Response response) {
      expect(response.id, equals('0'));
      expect(response.error, isNotNull);
      expect(
          response.error.code, equals(RequestErrorCode.SERVER_ALREADY_STARTED));
      channel2.expectMsgCount(responseCount: 2);
    });
  }

  static Future createAnalysisServer_successful() {
    SocketServer server = _createSocketServer();
    MockServerChannel channel = new MockServerChannel();
    server.createAnalysisServer(channel);
    channel.expectMsgCount(notificationCount: 1);
    expect(channel.notificationsReceived[0].event, SERVER_CONNECTED);
    return channel
        .sendRequest(new ServerShutdownParams().toRequest('0'))
        .then((Response response) {
      expect(response.id, equals('0'));
      expect(response.error, isNull);
      channel.expectMsgCount(responseCount: 1, notificationCount: 1);
    });
  }

  static Future requestHandler_exception() {
    SocketServer server = _createSocketServer();
    MockServerChannel channel = new MockServerChannel();
    server.createAnalysisServer(channel);
    channel.expectMsgCount(notificationCount: 1);
    expect(channel.notificationsReceived[0].event, SERVER_CONNECTED);
    _MockRequestHandler handler = new _MockRequestHandler(false);
    server.analysisServer.handlers = [handler];
    var request = new ServerGetVersionParams().toRequest('0');
    return channel.sendRequest(request).then((Response response) {
      expect(response.id, equals('0'));
      expect(response.error, isNotNull);
      expect(response.error.code, equals(RequestErrorCode.SERVER_ERROR));
      expect(response.error.message, equals('mock request exception'));
      expect(response.error.stackTrace, isNotNull);
      expect(response.error.stackTrace, isNotEmpty);
      channel.expectMsgCount(responseCount: 1, notificationCount: 1);
    });
  }

  static Future requestHandler_futureException() {
    SocketServer server = _createSocketServer();
    MockServerChannel channel = new MockServerChannel();
    server.createAnalysisServer(channel);
    _MockRequestHandler handler = new _MockRequestHandler(true);
    server.analysisServer.handlers = [handler];
    var request = new ServerGetVersionParams().toRequest('0');
    return channel.sendRequest(request).then((Response response) {
      expect(response.id, equals('0'));
      expect(response.error, isNull);
      channel.expectMsgCount(responseCount: 1, notificationCount: 2);
      expect(channel.notificationsReceived[1].event, SERVER_ERROR);
    });
  }

  static SocketServer _createSocketServer() {
    PhysicalResourceProvider resourceProvider =
        PhysicalResourceProvider.INSTANCE;
    ServerPlugin serverPlugin = new ServerPlugin();
    ExtensionManager manager = new ExtensionManager();
    manager.processPlugins([serverPlugin]);
    SdkCreator sdkCreator = (_) => new FolderBasedDartSdk(resourceProvider,
        FolderBasedDartSdk.defaultSdkDirectory(resourceProvider));
    return new SocketServer(
        new AnalysisServerOptions(),
        new DartSdkManager('', false, sdkCreator),
        sdkCreator(null),
        InstrumentationService.NULL_SERVICE,
        serverPlugin,
        null,
        null,
        false);
  }
}

class _MockRequestHandler implements RequestHandler {
  final bool futureException;

  _MockRequestHandler(this.futureException);

  @override
  Response handleRequest(Request request) {
    if (futureException) {
      new Future(throwException);
      return new Response(request.id);
    }
    throw 'mock request exception';
  }

  void throwException() {
    throw 'mock future exception';
  }
}
