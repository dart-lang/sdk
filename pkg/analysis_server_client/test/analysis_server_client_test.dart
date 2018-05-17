// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server_client/analysis_server_client.dart';
import 'package:test/test.dart';

void main() {
  MockProcess process;
  AnalysisServerClient serverWrapper;

  setUp(() async {
    process = new MockProcess();
    serverWrapper = new AnalysisServerClient(process);
  });

  test('test_listenToOutput_good', () async {
    process.stdout = _goodMessage();

    final future = serverWrapper.send('blahMethod', null);
    serverWrapper.listenToOutput();

    final response = await future;
    expect(response, new isInstanceOf<Map>());
    final responseAsMap = response as Map;
    expect(responseAsMap['foo'], 'bar');
  });

  test('test_listenToOutput_error', () async {
    process.stdout = _badMessage();
    final future = serverWrapper.send('blahMethod', null);
    future.catchError((e) {
      expect(e, new isInstanceOf<ServerErrorMessage>());
      final e2 = e as ServerErrorMessage;
      expect(e2.code, 'someErrorCode');
      expect(e2.message, 'something went wrong');
      expect(e2.stackTrace, 'some long stack trace');
    });
    serverWrapper.listenToOutput();
  });

  test('test_listenToOutput_event', () async {
    process.stdout = _eventMessage();

    void eventHandler(String event, Map<String, Object> params) {
      expect(event, 'fooEvent');
      expect(params.length, 2);
      expect(params['foo'] as String, 'bar');
      expect(params['baz'] as String, 'bang');
    }

    serverWrapper.send('blahMethod', null);
    serverWrapper.listenToOutput(notificationProcessor: eventHandler);
  });
}

final _badErrorMessage = {
  'code': 'someErrorCode',
  'message': 'something went wrong',
  'stackTrace': 'some long stack trace'
};

Stream<List<int>> _badMessage() async* {
  yield utf8.encoder.convert('Observatory listening on foo bar\n');
  final sampleJson = {'id': '0', 'error': _badErrorMessage};
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

class MockProcess implements Process {
  @override
  Stream<List<int>> stderr;

  @override
  IOSink stdin = new MockStdin();

  @override
  Stream<List<int>> stdout;

  @override
  Future<int> get exitCode => null;

  @override
  int get pid => null;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => null;
}

class MockStdin implements IOSink {
  @override
  Encoding encoding;

  @override
  Future get done => null;

  @override
  void add(List<int> data) {}

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
  void writeAll(Iterable objects, [String separator = ""]) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object obj = ""]) {}
}
