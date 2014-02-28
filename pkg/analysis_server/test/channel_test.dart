// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.channel;

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/matcher.dart';
import 'package:unittest/unittest.dart';
import 'package:analysis_server/src/channel.dart';
import 'mocks.dart';

main() {
  group('Channel', () {
    test('invalidJsonToClient', ChannelTest.invalidJsonToClient);
    test('invalidJsonToServer', ChannelTest.invalidJsonToServer);
    test('notification', ChannelTest.notification);
    test('request', ChannelTest.request);
    test('response', ChannelTest.response);
  });
}

class ChannelTest {

  static void invalidJsonToClient() {
    InvalidJsonMockSocket mockSocket = new InvalidJsonMockSocket();
    WebSocketClientChannel client = new WebSocketClientChannel(mockSocket);
    var responsesReceived = new List();
    var notificationsReceived = new List();
    client.listen((Response response) => responsesReceived.add(response),
        (Notification notification) => notificationsReceived.add(notification));

    mockSocket.addInvalid('"blat"');
    mockSocket.addInvalid('{foo:bar}');

    expect(responsesReceived.length, equals(0));
    expect(notificationsReceived.length, equals(0));
    expect(mockSocket.responseCount, equals(0));
  }

  static void invalidJsonToServer() {
    InvalidJsonMockSocket mockSocket = new InvalidJsonMockSocket();
    WebSocketServerChannel server = new WebSocketServerChannel(mockSocket);
    var received = new List();
    server.listen((Request request) => received.add(request));

    mockSocket.addInvalid('"blat"');
    mockSocket.addInvalid('{foo:bar}');

    expect(received.length, equals(0));
    expect(mockSocket.responseCount, equals(2));
  }

  static void notification() {
    MockSocket mockSocket = new MockSocket();
    WebSocketClientChannel client = new WebSocketClientChannel(mockSocket);
    WebSocketServerChannel server = new WebSocketServerChannel(mockSocket);
    var responsesReceived = new List();
    var notificationsReceived = new List();
    client.listen((Response response) => responsesReceived.add(response),
        (Notification notification) => notificationsReceived.add(notification));

    server.sendNotification(new Notification('myEvent'));

    expect(responsesReceived.length, equals(0));
    expect(notificationsReceived.length, equals(1));
    expect(notificationsReceived.first.runtimeType, equals(Notification));
    Notification actual = notificationsReceived.first;
    expect(actual.event, equals('myEvent'));
  }

  static void request() {
    MockSocket mockSocket = new MockSocket();
    WebSocketClientChannel client = new WebSocketClientChannel(mockSocket);
    WebSocketServerChannel server = new WebSocketServerChannel(mockSocket);
    var requestsReceived = new List();
    server.listen((Request request) => requestsReceived.add(request));

    client.sendRequest(new Request('myId', 'aMethod'));

    expect(requestsReceived.length, equals(1));
    expect(requestsReceived.first.runtimeType, equals(Request));
    Request actual = requestsReceived.first;
    expect(actual.id, equals('myId'));
    expect(actual.method, equals('aMethod'));
  }

  static void response() {
    MockSocket mockSocket = new MockSocket();
    WebSocketClientChannel client = new WebSocketClientChannel(mockSocket);
    WebSocketServerChannel server = new WebSocketServerChannel(mockSocket);
    var responsesReceived = new List();
    var notificationsReceived = new List();
    client.listen((Response response) => responsesReceived.add(response),
        (Notification notification) => notificationsReceived.add(notification));

    server.sendResponse(new Response('myId'));

    expect(responsesReceived.length, equals(1));
    expect(notificationsReceived.length, equals(0));
    expect(responsesReceived.first.runtimeType, equals(Response));
    Response actual = responsesReceived.first;
    expect(actual.id, equals('myId'));
  }
}