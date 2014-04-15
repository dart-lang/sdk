// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.channel;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/src/channel.dart';
import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import 'mocks.dart';

main() {
  group('WebSocketChannel', () {
    setUp(WebSocketChannelTest.setUp);
    test('close', WebSocketChannelTest.close);
    test('invalidJsonToClient', WebSocketChannelTest.invalidJsonToClient);
    test('invalidJsonToServer', WebSocketChannelTest.invalidJsonToServer);
    test('notification', WebSocketChannelTest.notification);
    test('notificationAndResponse', WebSocketChannelTest.notificationAndResponse);
    test('request', WebSocketChannelTest.request);
    test('requestResponse', WebSocketChannelTest.requestResponse);
    test('response', WebSocketChannelTest.response);
  });
  group('ByteStreamServerChannel', () {
    setUp(ByteStreamServerChannelTest.setUp);
    test('listen_wellFormedRequest',
        ByteStreamServerChannelTest.listen_wellFormedRequest);
    test('listen_invalidRequest',
        ByteStreamServerChannelTest.listen_invalidRequest);
    test('listen_invalidJson', ByteStreamServerChannelTest.listen_invalidJson);
    test('listen_streamError', ByteStreamServerChannelTest.listen_streamError);
    test('listen_streamDone', ByteStreamServerChannelTest.listen_streamDone);
    test('sendNotification', ByteStreamServerChannelTest.sendNotification);
    test('sendResponse', ByteStreamServerChannelTest.sendResponse);
  });
}

class WebSocketChannelTest {
  static MockSocket socket;
  static WebSocketClientChannel client;
  static WebSocketServerChannel server;

  static List requestsReceived;
  static List responsesReceived;
  static List notificationsReceived;

  static void setUp() {
    socket = new MockSocket.pair();
    client = new WebSocketClientChannel(socket);
    server = new WebSocketServerChannel(socket.twin);

    requestsReceived = [];
    responsesReceived = [];
    notificationsReceived = [];

    // Allow multiple listeners on server side for testing.
    socket.twin.allowMultipleListeners();

    server.listen(requestsReceived.add);
    client.responseStream.listen(responsesReceived.add);
    client.notificationStream.listen(notificationsReceived.add);
  }

  static Future close() {
    var timeout = new Duration(seconds: 1);
    var future = client.responseStream.drain().timeout(timeout);
    client.close();
    return future;
  }

  static Future invalidJsonToClient() {
    var result = client.responseStream
        .first
        .timeout(new Duration(seconds: 1))
        .then((Response response) {
          expect(response.id, equals('myId'));
          expectMsgCount(responseCount: 1);
        });
    socket.twin.add('{"foo":"bar"}');
    server.sendResponse(new Response('myId'));
    return result;
  }

  static Future invalidJsonToServer() {
    var result = client.responseStream
        .first
        .timeout(new Duration(seconds: 1))
        .then((Response response) {
          expect(response.id, equals(''));
          expect(response.error, isNotNull);
          expectMsgCount(responseCount: 1);
        });
    socket.add('"blat"');
    return result;
  }

  static Future notification() {
    var result = client.notificationStream
        .first
        .timeout(new Duration(seconds: 1))
        .then((Notification notification) {
          expect(notification.event, equals('myEvent'));
          expectMsgCount(notificationCount: 1);
          expect(notificationsReceived.first, equals(notification));
        });
    server.sendNotification(new Notification('myEvent'));
    return result;
  }

  static Future notificationAndResponse() {
    var result = Future
        .wait([
          client.notificationStream.first,
          client.responseStream.first])
        .timeout(new Duration(seconds: 1))
        .then((_) => expectMsgCount(responseCount: 1, notificationCount: 1));
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
    server.listen((Request request) =>
        server.sendResponse(new Response(request.id)));
    return client.sendRequest(new Request('myId', 'myMth'))
        .timeout(new Duration(seconds: 1))
        .then((Response response) {
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
    return client.responseStream
        .first
        .timeout(new Duration(seconds: 1))
        .then((Response response) {
          expect(response.id, equals('myId'));
          expectMsgCount(responseCount: 1);
        });
  }

  static void expectMsgCount({requestCount: 0,
                              responseCount: 0,
                              notificationCount: 0}) {
    expect(requestsReceived, hasLength(requestCount));
    expect(responsesReceived, hasLength(responseCount));
    expect(notificationsReceived, hasLength(notificationCount));
  }
}

class ByteStreamServerChannelTest {
  static ByteStreamServerChannel channel;

  /**
   * Sink that may be used to deliver data to the channel, as though it's
   * coming from the client.
   */
  static IOSink inputSink;

  /**
   * Stream of lines sent back to the client by the channel.
   */
  static Stream<String> outputLineStream;

  /**
   * Stream of requests received from the channel via [listen()].
   */
  static Stream<Request> requestStream;

  /**
   * Stream of errors received from the channel via [listen()].
   */
  static Stream errorStream;

  /**
   * Future which is completed when then [listen()] reports [onDone].
   */
  static Future doneFuture;

  static void setUp() {
    StreamController<List<int>> inputStream = new StreamController<List<int>>();
    inputSink = new IOSink(inputStream);
    StreamController<List<int>> outputStream = new StreamController<List<int>>(
        );
    outputLineStream = outputStream.stream.transform((new Utf8Codec()).decoder
        ).transform(new LineSplitter());
    IOSink outputSink = new IOSink(outputStream);
    channel = new ByteStreamServerChannel(inputStream.stream, outputSink);
    StreamController<Request> requestStreamController =
        new StreamController<Request>();
    requestStream = requestStreamController.stream;
    StreamController errorStreamController = new StreamController();
    errorStream = errorStreamController.stream;
    Completer doneCompleter = new Completer();
    doneFuture = doneCompleter.future;
    channel.listen((Request request) {
      requestStreamController.add(request);
    }, onError: (error) {
      errorStreamController.add(error);
    }, onDone: () {
      doneCompleter.complete();
    });
  }

  static Future listen_wellFormedRequest() {
    inputSink.writeln('{"id":"0","method":"server.version"}');
    return inputSink.flush().then((_) => requestStream.first.timeout(
        new Duration(seconds: 1))).then((Request request) {
      expect(request.id, equals("0"));
      expect(request.method, equals("server.version"));
    });
  }

  static Future listen_invalidRequest() {
    inputSink.writeln('{"id":"0"}');
    return inputSink.flush().then((_) => outputLineStream.first.timeout(
        new Duration(seconds: 1))).then((String response) {
      var jsonResponse = new JsonCodec().decode(response);
      expect(jsonResponse, isMap);
      expect(jsonResponse, contains('error'));
      expect(jsonResponse['error'], isNotNull);
    });
  }

  static Future listen_invalidJson() {
    inputSink.writeln('{"id":');
    return inputSink.flush().then((_) => outputLineStream.first.timeout(
        new Duration(seconds: 1))).then((String response) {
      var jsonResponse = new JsonCodec().decode(response);
      expect(jsonResponse, isMap);
      expect(jsonResponse, contains('error'));
      expect(jsonResponse['error'], isNotNull);
    });
  }

  static Future listen_streamError() {
    var error = new Error();
    inputSink.addError(error);
    return inputSink.flush().then((_) => errorStream.first.timeout(new Duration(
        seconds: 1))).then((var receivedError) {
      expect(receivedError, same(error));
    });
  }

  static Future listen_streamDone() {
    return inputSink.close().then((_) => doneFuture.timeout(new Duration(
        seconds: 1)));
  }

  static Future sendNotification() {
    channel.sendNotification(new Notification('foo'));
    return outputLineStream.first.timeout(new Duration(seconds: 1)).then((String
        notification) {
      var jsonNotification = new JsonCodec().decode(notification);
      expect(jsonNotification, isMap);
      expect(jsonNotification, contains('event'));
      expect(jsonNotification['event'], equals('foo'));
    });
  }

  static Future sendResponse() {
    channel.sendResponse(new Response('foo'));
    return outputLineStream.first.timeout(new Duration(seconds: 1)).then((String
        response) {
      var jsonResponse = new JsonCodec().decode(response);
      expect(jsonResponse, isMap);
      expect(jsonResponse, contains('id'));
      expect(jsonResponse['id'], equals('foo'));
    });
  }
}
