// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.channel.web_socket;

import 'dart:async';

import 'package:analysis_server/src/channel/web_socket_channel.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:unittest/unittest.dart';

import '../mocks.dart';

main() {
  group('WebSocketChannel', () {
    setUp(WebSocketChannelTest.setUp);
    test('close', WebSocketChannelTest.close);
    test('invalidJsonToClient', WebSocketChannelTest.invalidJsonToClient);
    test('invalidJsonToServer', WebSocketChannelTest.invalidJsonToServer);
    test('notification', WebSocketChannelTest.notification);
    test(
        'notificationAndResponse',
        WebSocketChannelTest.notificationAndResponse);
    test('request', WebSocketChannelTest.request);
    test('requestResponse', WebSocketChannelTest.requestResponse);
    test('response', WebSocketChannelTest.response);
  });
}

class WebSocketChannelTest {
  static MockSocket socket;
  static WebSocketClientChannel client;
  static WebSocketServerChannel server;

  static List requestsReceived;
  static List responsesReceived;
  static List notificationsReceived;

  static Future close() {
    var timeout = new Duration(seconds: 1);
    var future = client.responseStream.drain().timeout(timeout);
    client.close();
    return future;
  }

  static void expectMsgCount({requestCount: 0, responseCount: 0,
      notificationCount: 0}) {
    expect(requestsReceived, hasLength(requestCount));
    expect(responsesReceived, hasLength(responseCount));
    expect(notificationsReceived, hasLength(notificationCount));
  }

  static Future invalidJsonToClient() {
    var result = client.responseStream.first.timeout(
        new Duration(seconds: 1)).then((Response response) {
      expect(response.id, equals('myId'));
      expectMsgCount(responseCount: 1);
    });
    socket.twin.add('{"foo":"bar"}');
    server.sendResponse(new Response('myId'));
    return result;
  }

  static Future invalidJsonToServer() {
    var result = client.responseStream.first.timeout(
        new Duration(seconds: 1)).then((Response response) {
      expect(response.id, equals(''));
      expect(response.error, isNotNull);
      expectMsgCount(responseCount: 1);
    });
    socket.add('"blat"');
    return result;
  }

  static Future notification() {
    var result = client.notificationStream.first.timeout(
        new Duration(seconds: 1)).then((Notification notification) {
      expect(notification.event, equals('myEvent'));
      expectMsgCount(notificationCount: 1);
      expect(notificationsReceived.first, equals(notification));
    });
    server.sendNotification(new Notification('myEvent'));
    return result;
  }

  static Future notificationAndResponse() {
    var result = Future.wait(
        [
            client.notificationStream.first,
            client.responseStream.first]).timeout(
                new Duration(
                    seconds: 1)).then(
                        (_) => expectMsgCount(responseCount: 1, notificationCount: 1));
    server
        ..sendNotification(new Notification('myEvent'))
        ..sendResponse(new Response('myId'));
    return result;
  }

  static void request() {
    client.sendRequest(new Request('myId', 'myMth'));
    server.listen((Request request) {
      expect(request.id, equals('myId'));
      expect(request.method, equals('myMth'));
      expectMsgCount(requestCount: 1);
    });
  }

  static Future requestResponse() {
    // Simulate server sending a response by echoing the request.
    server.listen(
        (Request request) => server.sendResponse(new Response(request.id)));
    return client.sendRequest(
        new Request(
            'myId',
            'myMth')).timeout(new Duration(seconds: 1)).then((Response response) {
      expect(response.id, equals('myId'));
      expectMsgCount(requestCount: 1, responseCount: 1);

      expect(requestsReceived.first is Request, isTrue);
      Request request = requestsReceived.first;
      expect(request.id, equals('myId'));
      expect(request.method, equals('myMth'));
      expect(responsesReceived.first, equals(response));
    });
  }

  static Future response() {
    server.sendResponse(new Response('myId'));
    return client.responseStream.first.timeout(
        new Duration(seconds: 1)).then((Response response) {
      expect(response.id, equals('myId'));
      expectMsgCount(responseCount: 1);
    });
  }

  static void setUp() {
    socket = new MockSocket.pair();
    client = new WebSocketClientChannel(socket);
    server =
        new WebSocketServerChannel(socket.twin, new NullInstrumentationServer());

    requestsReceived = [];
    responsesReceived = [];
    notificationsReceived = [];

    // Allow multiple listeners on server side for testing.
    socket.twin.allowMultipleListeners();

    server.listen(requestsReceived.add);
    client.responseStream.listen(responsesReceived.add);
    client.notificationStream.listen(notificationsReceived.add);
  }
}
