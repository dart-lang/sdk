// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server_client/protocol.dart';
import 'package:analysis_server_client/server.dart';
import 'package:test/test.dart';

void main() {
  MockProcess process;
  Server server;

  setUp(() async {
    process = MockProcess();
    server = Server(process: process);
  });

  group('listenToOutput', () {
    test('good', () async {
      process.stdout = _goodMessage();
      process.stderr = _noMessage();

      final future = server.send('blahMethod', null);
      server.listenToOutput();

      final response = await future;
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
      });
      server.listenToOutput();
    });

    test('event', () async {
      process.stdout = _eventMessage();
      process.stderr = _noMessage();

      final completer = Completer();
      void eventHandler(Notification notification) {
        expect(notification.event, 'fooEvent');
        expect(notification.params.length, 2);
        expect(notification.params['foo'] as String, 'bar');
        expect(notification.params['baz'] as String, 'bang');
        completer.complete();
      }

      // ignore: unawaited_futures
      server.send('blahMethod', null);
      server.listenToOutput(notificationProcessor: eventHandler);
      await completer.future;
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
        mockout.add(utf8.encoder.convert('$encoded\n'));
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
  yield utf8.encoder.convert('Observatory listening on foo bar\n');
  final sampleJson = {
    'id': '0',
    'error': _badErrorMessage,
  };
  yield utf8.encoder.convert(json.encode(sampleJson));
}

Stream<List<int>> _eventMessage() async* {
  yield utf8.encoder.convert('Observatory listening on foo bar\n');
  final sampleJson = {
    'event': 'fooEvent',
    'params': {'foo': 'bar', 'baz': 'bang'}
  };
  yield utf8.encoder.convert(json.encode(sampleJson));
}

Stream<List<int>> _goodMessage() async* {
  yield utf8.encoder.convert('Observatory listening on foo bar\n');
  final sampleJson = {
    'id': '0',
    'result': {'foo': 'bar'}
  };
  yield utf8.encoder.convert(json.encode(sampleJson));
}

Stream<List<int>> _noMessage() async* {
  yield utf8.encoder.convert('');
}

class MockProcess implements Process {
  MockStdin mockin = MockStdin();

  bool killed = false;

  @override
  Stream<List<int>> stderr;

  @override
  Stream<List<int>> stdout;

  @override
  Future<int> exitCode;

  @override
  int get pid => null;

  @override
  IOSink get stdin => mockin;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    var wasKilled = killed;
    killed = true;
    return !wasKilled;
  }
}

class MockStdin implements IOSink {
  final controller = StreamController<String>();

  @override
  Encoding encoding;

  @override
  Future get done => null;

  @override
  void add(List<int> data) {
    controller.add(utf8.decode(data));
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {}

  @override
  Future addStream(Stream<List<int>> stream) => null;

  @override
  Future close() => null;

  @override
  Future flush() => null;

  @override
  void write(Object obj) {}

  @override
  void writeAll(Iterable objects, [String separator = '']) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object obj = '']) {}
}
