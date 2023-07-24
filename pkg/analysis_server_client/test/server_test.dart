// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server_client/listener/server_listener.dart';
import 'package:analysis_server_client/protocol.dart';
import 'package:analysis_server_client/server.dart';
import 'package:test/test.dart';

void main() {
  late _ServerListener listener;
  late MockProcess process;
  late Server server;

  setUp(() async {
    process = MockProcess();
    listener = _ServerListener();
    server = Server(process: process, listener: listener);
  });

  group('listenToOutput', () {
    test('good', () async {
      process.stdout = _goodMessage();
      process.stderr = _noMessage();

      final future = server.send('blahMethod', null);
      server.listenToOutput();

      final response = (await future)!;
      expect(response['foo'], 'bar');
    });

    test('error', () async {
      process.stdout = _badMessage();
      process.stderr = _noMessage();

      final future = server.send('blahMethod', null);
      // ignore: unawaited_futures
      future.catchError((e) {
        expect(e, const TypeMatcher<RequestError>());
        final error = e as RequestError;
        expect(error.code, RequestErrorCode.UNKNOWN_REQUEST);
        expect(error.message, 'something went wrong');
        expect(error.stackTrace, 'some long stack trace');
        return <String, Object?>{};
      });
      server.listenToOutput();
    });

    test('event', () async {
      process.stdout = _eventMessage();
      process.stderr = _noMessage();

      final completer = Completer();
      void eventHandler(Notification notification) {
        expect(notification.event, 'fooEvent');
        var params = notification.params!;
        expect(params.length, 2);
        expect(params['foo'] as String, 'bar');
        expect(params['baz'] as String, 'bang');
        completer.complete();
      }

      // ignore: unawaited_futures
      server.send('blahMethod', null);
      server.listenToOutput(notificationProcessor: eventHandler);
      await completer.future;
    });

    test('unexpected message', () async {
      // No 'id', so not a response.
      // No 'event', so not a notification.
      process.stdout = Stream.value(
        utf8.encode(json.encode({'foo': 'bar'})),
      );
      process.stderr = _noMessage();

      server.listenToOutput();

      // Must happen for the test to pass.
      await listener.unexpectedMessageController.stream.first;
    });

    test('unexpected notification format', () async {
      process.stdout = Stream.value(
        utf8.encode(json.encode({'event': 'foo', 'noParams': '42'})),
      );
      process.stderr = _noMessage();

      server.listenToOutput();

      // Must happen for the test to pass.
      await listener.unexpectedNotificationFormatCompleter.stream.first;
    });

    test('unexpected response', () async {
      // We have no asked anything, but got a response.
      process.stdout = Stream.value(
        utf8.encode(json.encode({'id': '0'})),
      );
      process.stderr = _noMessage();

      server.listenToOutput();

      // Must happen for the test to pass.
      await listener.unexpectedResponseCompleter.stream.first;
    });

    test('unexpected response format', () async {
      // We expect that the first request has id `0`.
      // The response is invalid - the "result" field is not an object.
      process.stdout = Stream.value(
        utf8.encode(json.encode({'id': '0', 'result': '42'})),
      );
      process.stderr = _noMessage();

      // ignore: unawaited_futures
      server.send('blahMethod', null);
      server.listenToOutput();

      // Must happen for the test to pass.
      await listener.unexpectedResponseFormatCompleter.stream.first;
    });
  });

  group('stop', () {
    test('ok', () async {
      final mockout = StreamController<List<int>>();
      process.stdout = mockout.stream;
      process.stderr = _noMessage();
      // ignore: unawaited_futures
      process.mockin.controller.stream.first.then((_) {
        var encoded = json.encode({'id': '0'});
        mockout.add(utf8.encode('$encoded\n'));
      });
      process.exitCode = Future.value(0);

      server.listenToOutput();
      await server.stop(timeLimit: const Duration(milliseconds: 1));
      expect(process.killed, isFalse);
    });
    test('stopped', () async {
      final mockout = StreamController<List<int>>();
      process.stdout = mockout.stream;
      process.stderr = _noMessage();
      process.exitCode = Future.value(0);

      server.listenToOutput();
      await server.stop(timeLimit: const Duration(milliseconds: 1));
      expect(process.killed, isFalse);
    });
    test('kill', () async {
      final mockout = StreamController<List<int>>();
      process.stdout = mockout.stream;
      process.stderr = _noMessage();
      process.exitCode = Future.delayed(const Duration(seconds: 1), () => 0);

      server.listenToOutput();
      await server.stop(timeLimit: const Duration(milliseconds: 10));
      expect(process.killed, isTrue);
    });
  });
}

final _badErrorMessage = {
  'code': 'UNKNOWN_REQUEST',
  'message': 'something went wrong',
  'stackTrace': 'some long stack trace'
};

Stream<List<int>> _badMessage() async* {
  yield utf8.encode('The Dart VM service is listening on foo bar\n');
  final sampleJson = {
    'id': '0',
    'error': _badErrorMessage,
  };
  yield utf8.encode(json.encode(sampleJson));
}

Stream<List<int>> _eventMessage() async* {
  yield utf8.encode('The Dart VM service is listening on foo bar\n');
  final sampleJson = {
    'event': 'fooEvent',
    'params': {'foo': 'bar', 'baz': 'bang'}
  };
  yield utf8.encode(json.encode(sampleJson));
}

Stream<List<int>> _goodMessage() async* {
  yield utf8.encode('The Dart VM service is listening on foo bar\n');
  final sampleJson = {
    'id': '0',
    'result': {'foo': 'bar'}
  };
  yield utf8.encode(json.encode(sampleJson));
}

Stream<List<int>> _noMessage() async* {
  yield utf8.encode('');
}

class MockProcess implements Process {
  MockStdin mockin = MockStdin();

  bool killed = false;

  @override
  late Stream<List<int>> stderr;

  @override
  late Stream<List<int>> stdout;

  @override
  late Future<int> exitCode;

  @override
  IOSink get stdin => mockin;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    var wasKilled = killed;
    killed = true;
    return !wasKilled;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockStdin implements IOSink {
  final controller = StreamController<String>();

  @override
  void add(List<int> data) {
    controller.add(utf8.decode(data));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ServerListener with ServerListener {
  final unexpectedMessageController = StreamController<Object>();
  final unexpectedNotificationFormatCompleter = StreamController<Object>();
  final unexpectedResponseCompleter = StreamController<Object>();
  final unexpectedResponseFormatCompleter = StreamController<Object>();

  @override
  void log(String prefix, String details) {}

  @override
  void unexpectedMessage(Map<String, Object?> message) {
    unexpectedMessageController.add(message);
  }

  @override
  void unexpectedNotificationFormat(Map<String, Object?> message) {
    unexpectedNotificationFormatCompleter.add(message);
  }

  @override
  void unexpectedResponse(Map<String, Object?> message, Object id) {
    unexpectedResponseCompleter.add(message);
  }

  @override
  void unexpectedResponseFormat(Map<String, Object?> message) {
    unexpectedResponseFormatCompleter.add(message);
  }
}
