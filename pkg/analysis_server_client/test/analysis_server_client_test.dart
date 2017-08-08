// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server_client/analysis_server_client.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  Process _process;
  AnalysisServerClient serverWrapper;

  setUp(() async {
    _process = new MockProcess();
    serverWrapper = new AnalysisServerClient(_process);
    when(_process.stdin).thenReturn(<int>[]);
  });

  test('test_listenToOutput_good', () async {
    when(_process.stdout).thenReturn(_goodMessage());

    final future = serverWrapper.send('blahMethod', null);
    serverWrapper.listenToOutput();

    final response = await future;
    expect(response, new isInstanceOf<Map>());
    final responseAsMap = response as Map;
    expect(responseAsMap['foo'], 'bar');
  });

  test('test_listenToOutput_error', () async {
    when(_process.stdout).thenReturn(_badMessage());
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
    when(_process.stdout).thenReturn(_eventMessage());

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

Stream<List<int>> _goodMessage() async* {
  yield UTF8.encoder.convert('Observatory listening on foo bar\n');
  final sampleJson = {
    'id': '0',
    'result': {'foo': 'bar'}
  };
  yield UTF8.encoder.convert(JSON.encode(sampleJson));
}

final _badErrorMessage = {
  'code': 'someErrorCode',
  'message': 'something went wrong',
  'stackTrace': 'some long stack trace'
};

Stream<List<int>> _badMessage() async* {
  yield UTF8.encoder.convert('Observatory listening on foo bar\n');
  final sampleJson = {'id': '0', 'error': _badErrorMessage};
  yield UTF8.encoder.convert(JSON.encode(sampleJson));
}

Stream<List<int>> _eventMessage() async* {
  yield UTF8.encoder.convert('Observatory listening on foo bar\n');
  final sampleJson = {
    'event': 'fooEvent',
    'params': {'foo': 'bar', 'baz': 'bang'}
  };
  yield UTF8.encoder.convert(JSON.encode(sampleJson));
}

class MockProcess extends Mock implements Process {}
