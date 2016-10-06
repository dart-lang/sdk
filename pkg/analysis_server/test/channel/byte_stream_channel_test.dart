// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.channel.byte_stream;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analysis_server/src/channel/byte_stream_channel.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:test/test.dart';

import '../mocks.dart';

main() {
  group('ByteStreamClientChannel', () {
    setUp(ByteStreamClientChannelTest.setUp);
    test('close', ByteStreamClientChannelTest.close);
    test(
        'listen_notification', ByteStreamClientChannelTest.listen_notification);
    test('listen_response', ByteStreamClientChannelTest.listen_response);
    test('sendRequest', ByteStreamClientChannelTest.sendRequest);
  });
  group('ByteStreamServerChannel', () {
    setUp(ByteStreamServerChannelTest.setUp);
    test('closed', ByteStreamServerChannelTest.closed);
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

class ByteStreamClientChannelTest {
  static ByteStreamClientChannel channel;

  /**
   * Sink that may be used to deliver data to the channel, as though it's
   * coming from the server.
   */
  static IOSink inputSink;

  /**
   * Sink through which the channel delivers data to the server.
   */
  static IOSink outputSink;

  /**
   * Stream of lines sent back to the client by the channel.
   */
  static Stream<String> outputLineStream;

  static Future close() {
    bool doneCalled = false;
    bool closeCalled = false;
    // add listener so that outputSink will trigger done/close futures
    outputLineStream.listen((_) {/* no-op */});
    outputSink.done.then((_) {
      doneCalled = true;
    });
    channel.close().then((_) {
      closeCalled = true;
    });
    return pumpEventQueue().then((_) {
      expect(doneCalled, isTrue);
      expect(closeCalled, isTrue);
    });
  }

  static Future listen_notification() {
    List<Notification> notifications = [];
    channel.notificationStream.forEach((n) => notifications.add(n));
    inputSink.writeln('{"event":"server.connected"}');
    return pumpEventQueue().then((_) {
      expect(notifications.length, equals(1));
      expect(notifications[0].event, equals('server.connected'));
    });
  }

  static Future listen_response() {
    List<Response> responses = [];
    channel.responseStream.forEach((n) => responses.add(n));
    inputSink.writeln('{"id":"72"}');
    return pumpEventQueue().then((_) {
      expect(responses.length, equals(1));
      expect(responses[0].id, equals('72'));
    });
  }

  static Future sendRequest() {
    int assertCount = 0;
    Request request = new Request('72', 'foo.bar');
    outputLineStream.first.then((line) => JSON.decode(line)).then((json) {
      expect(json[Request.ID], equals('72'));
      expect(json[Request.METHOD], equals('foo.bar'));
      inputSink.writeln('{"id":"73"}');
      inputSink.writeln('{"id":"72"}');
      assertCount++;
    });
    channel.sendRequest(request).then((Response response) {
      expect(response.id, equals('72'));
      assertCount++;
    });
    return pumpEventQueue().then((_) => expect(assertCount, equals(2)));
  }

  static void setUp() {
    var inputStream = new StreamController<List<int>>();
    inputSink = new IOSink(inputStream);
    var outputStream = new StreamController<List<int>>();
    outputLineStream = outputStream.stream
        .transform((new Utf8Codec()).decoder)
        .transform(new LineSplitter());
    outputSink = new IOSink(outputStream);
    channel = new ByteStreamClientChannel(inputStream.stream, outputSink);
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

  static Future closed() {
    return inputSink
        .close()
        .then((_) => channel.closed.timeout(new Duration(seconds: 1)));
  }

  static Future listen_invalidJson() {
    inputSink.writeln('{"id":');
    return inputSink
        .flush()
        .then((_) => outputLineStream.first.timeout(new Duration(seconds: 1)))
        .then((String response) {
      var jsonResponse = new JsonCodec().decode(response);
      expect(jsonResponse, isMap);
      expect(jsonResponse, contains('error'));
      expect(jsonResponse['error'], isNotNull);
    });
  }

  static Future listen_invalidRequest() {
    inputSink.writeln('{"id":"0"}');
    return inputSink
        .flush()
        .then((_) => outputLineStream.first.timeout(new Duration(seconds: 1)))
        .then((String response) {
      var jsonResponse = new JsonCodec().decode(response);
      expect(jsonResponse, isMap);
      expect(jsonResponse, contains('error'));
      expect(jsonResponse['error'], isNotNull);
    });
  }

  static Future listen_streamDone() {
    return inputSink
        .close()
        .then((_) => doneFuture.timeout(new Duration(seconds: 1)));
  }

  static Future listen_streamError() {
    var error = new Error();
    inputSink.addError(error);
    return inputSink
        .flush()
        .then((_) => errorStream.first.timeout(new Duration(seconds: 1)))
        .then((var receivedError) {
      expect(receivedError, same(error));
    });
  }

  static Future listen_wellFormedRequest() {
    inputSink.writeln('{"id":"0","method":"server.version"}');
    return inputSink
        .flush()
        .then((_) => requestStream.first.timeout(new Duration(seconds: 1)))
        .then((Request request) {
      expect(request.id, equals("0"));
      expect(request.method, equals("server.version"));
    });
  }

  static Future sendNotification() {
    channel.sendNotification(new Notification('foo'));
    return outputLineStream.first
        .timeout(new Duration(seconds: 1))
        .then((String notification) {
      var jsonNotification = new JsonCodec().decode(notification);
      expect(jsonNotification, isMap);
      expect(jsonNotification, contains('event'));
      expect(jsonNotification['event'], equals('foo'));
    });
  }

  static Future sendResponse() {
    channel.sendResponse(new Response('foo'));
    return outputLineStream.first
        .timeout(new Duration(seconds: 1))
        .then((String response) {
      var jsonResponse = new JsonCodec().decode(response);
      expect(jsonResponse, isMap);
      expect(jsonResponse, contains('id'));
      expect(jsonResponse['id'], equals('foo'));
    });
  }

  static void setUp() {
    StreamController<List<int>> inputStream = new StreamController<List<int>>();
    inputSink = new IOSink(inputStream);
    StreamController<List<int>> outputStream =
        new StreamController<List<int>>();
    outputLineStream = outputStream.stream
        .transform((new Utf8Codec()).decoder)
        .transform(new LineSplitter());
    IOSink outputSink = new IOSink(outputStream);
    channel = new ByteStreamServerChannel(
        inputStream.stream, outputSink, InstrumentationService.NULL_SERVICE);
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
}
