// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/src/channel/byte_stream_channel.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ByteStreamClientChannelTest);
    defineReflectiveTests(ByteStreamServerChannelTest);
  });
}

@reflectiveTest
class ByteStreamClientChannelTest {
  late ByteStreamClientChannel channel;

  /// Sink that may be used to deliver data to the channel, as though it's
  /// coming from the server.
  late IOSink inputSink;

  /// Sink through which the channel delivers data to the server.
  late IOSink outputSink;

  /// Stream of lines sent back to the client by the channel.
  late Stream<String> outputLineStream;

  void setUp() {
    var inputStream = StreamController<List<int>>();
    inputSink = IOSink(inputStream);
    var outputStream = StreamController<List<int>>();
    outputLineStream = outputStream.stream
        .transform(Utf8Codec().decoder)
        .transform(LineSplitter());
    outputSink = IOSink(outputStream);
    channel = ByteStreamClientChannel(inputStream.stream, outputSink);
  }

  Future<void> test_close() {
    var doneCalled = false;
    var closeCalled = false;
    // add listener so that outputSink will trigger done/close futures
    outputLineStream.listen((_) {
      /* no-op */
    });
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

  Future<void> test_listen_notification() {
    var notifications = <Notification>[];
    channel.notificationStream.forEach((n) => notifications.add(n));
    inputSink.writeln('{"event":"server.connected"}');
    return pumpEventQueue().then((_) {
      expect(notifications.length, equals(1));
      expect(notifications[0].event, equals('server.connected'));
    });
  }

  Future<void> test_listen_response() {
    var responses = <Response>[];
    channel.responseStream.forEach((n) => responses.add(n));
    inputSink.writeln('{"id":"72"}');
    return pumpEventQueue().then((_) {
      expect(responses.length, equals(1));
      expect(responses[0].id, equals('72'));
    });
  }

  Future<void> test_sendRequest() {
    var assertCount = 0;
    var request = Request('72', 'foo.bar');
    outputLineStream.first.then((line) => json.decode(line)).then((json) {
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
}

@reflectiveTest
class ByteStreamServerChannelTest {
  late ByteStreamServerChannel channel;

  /// Sink that may be used to deliver data to the channel, as though it's
  /// coming from the client.
  late IOSink inputSink;

  /// Stream of lines sent back to the client by the channel.
  late Stream<String> outputLineStream;

  /// Stream of requests received from the channel via [listen()].
  late Stream<RequestOrResponse> requestStream;

  /// Stream of errors received from the channel via [listen()].
  late Stream<Object?> errorStream;

  /// Future which is completed when then [listen()] reports [onDone].
  late Future<void> doneFuture;

  void setUp() {
    var inputStream = StreamController<List<int>>();
    inputSink = IOSink(inputStream);
    var outputStream = StreamController<List<int>>();
    outputLineStream = outputStream.stream
        .transform(Utf8Codec().decoder)
        .transform(LineSplitter());
    var outputSink = IOSink(outputStream);
    channel = InputOutputByteStreamServerChannel(
      inputStream.stream,
      outputSink,
      InstrumentationService.NULL_SERVICE,
    );
    var requestStreamController = StreamController<RequestOrResponse>();
    requestStream = requestStreamController.stream;
    var errorStreamController = StreamController<Object?>();
    errorStream = errorStreamController.stream;
    var doneCompleter = Completer();
    doneFuture = doneCompleter.future;
    channel.requests.listen(
      (RequestOrResponse requestOrResponse) {
        requestStreamController.add(requestOrResponse);
      },
      onError: (error) {
        errorStreamController.add(error);
      },
      onDone: () {
        doneCompleter.complete();
      },
    );
  }

  Future<void> test_closed() {
    return inputSink.close().then(
      (_) => channel.closed.timeout(Duration(seconds: 1)),
    );
  }

  Future<void> test_listen_invalidJson() {
    inputSink.writeln('{"id":');
    return inputSink
        .flush()
        .then((_) => outputLineStream.first.timeout(Duration(seconds: 1)))
        .then((String response) {
          var jsonResponse = JsonCodec().decode(response);
          expect(jsonResponse, isMap);
          expect(jsonResponse, contains('error'));
          expect(jsonResponse['error'], isNotNull);
        });
  }

  Future<void> test_listen_invalidRequest() {
    inputSink.writeln('{"garbage":"true"}');
    return inputSink
        .flush()
        .then((_) => outputLineStream.first.timeout(Duration(seconds: 1)))
        .then((String response) {
          var jsonResponse = JsonCodec().decode(response);
          expect(jsonResponse, isMap);
          expect(jsonResponse, contains('error'));
          expect(jsonResponse['error'], isNotNull);
        });
  }

  Future<void> test_listen_streamDone() {
    return inputSink.close().then(
      (_) => doneFuture.timeout(Duration(seconds: 1)),
    );
  }

  Future<void> test_listen_streamError() {
    var error = Error();
    inputSink.addError(error);
    return inputSink
        .flush()
        .then((_) => errorStream.first.timeout(Duration(seconds: 1)))
        .then((var receivedError) {
          expect(receivedError, same(error));
        });
  }

  Future<void> test_listen_wellFormedRequest() {
    inputSink.writeln('{"id":"0","method":"server.version"}');
    return inputSink
        .flush()
        .then((_) => requestStream.first.timeout(Duration(seconds: 1)))
        .then((RequestOrResponse requestOrResponse) {
          if (requestOrResponse is! Request) {
            fail('Expected a Request');
          }
          expect(requestOrResponse.id, equals('0'));
          expect(requestOrResponse.method, equals('server.version'));
        });
  }

  Future<void> test_sendNotification() {
    channel.sendNotification(Notification('foo'));
    return outputLineStream.first.timeout(Duration(seconds: 1)).then((
      String notification,
    ) {
      var jsonNotification = JsonCodec().decode(notification);
      expect(jsonNotification, isMap);
      expect(jsonNotification, contains('event'));
      expect(jsonNotification['event'], equals('foo'));
    });
  }

  Future<void> test_sendNotification_exceptionInSink() async {
    // This IOSink asynchronously throws an exception on any writeln().
    var outputSink = _IOSinkThatAsyncThrowsOnWrite();

    var channel = InputOutputByteStreamServerChannel(
      StreamController<List<int>>().stream,
      outputSink,
      InstrumentationService.NULL_SERVICE,
    );

    // Attempt to send a notification.
    channel.sendNotification(Notification('foo'));

    // An exception was thrown, it did not leak, but the channel was closed.
    await channel.closed;
  }

  Future<void> test_sendResponse() {
    channel.sendResponse(Response('foo'));
    return outputLineStream.first.timeout(Duration(seconds: 1)).then((
      String response,
    ) {
      var jsonResponse = JsonCodec().decode(response);
      expect(jsonResponse, isMap);
      expect(jsonResponse, contains('id'));
      expect(jsonResponse['id'], equals('foo'));
    });
  }
}

class _IOSinkThatAsyncThrowsOnWrite implements IOSink {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  @override
  void writeln([Object? obj = '']) {
    Timer(Duration(milliseconds: 10), () {
      throw '42';
    });
  }
}
