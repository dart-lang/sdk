// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:analysis_server_client/protocol.dart';
import 'package:async/src/stream_sink_transformer.dart';
import 'package:nnbd_migration/isolate_server.dart';
import 'package:stream_channel/isolate_channel.dart';
import 'package:stream_channel/src/stream_channel_transformer.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';

void main() {
  FakeIsolate isolate;
  FakeIsolateChannel isolateChannel;
  Server server;

  setUp(() async {
    isolate = FakeIsolate();
    isolateChannel = FakeIsolateChannel();
    server = Server(isolate: isolate, isolateChannel: isolateChannel);
  });

  group('listenToOutput', () {
    test('good', () async {
      isolateChannel.stream = _goodMessage();

      final future = server.send('blahMethod', null);
      server.listenToOutput();

      final response = await future;
      expect(response['foo'], 'bar');
    });

    test('error', () async {
      isolateChannel.stream = _badMessage();

      final future = server.send('blahMethod', null);
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
      isolateChannel.stream = _eventMessage();

      final completer = Completer();
      void eventHandler(Notification notification) {
        expect(notification.event, 'fooEvent');
        expect(notification.params.length, 2);
        expect(notification.params['foo'] as String, 'bar');
        expect(notification.params['baz'] as String, 'bang');
        completer.complete();
      }

      server.send('blahMethod', null);
      server.listenToOutput(notificationProcessor: eventHandler);
      await completer.future;
    });
  });

  group('stop', () {
    test('ok', () async {
      final fakeOut = StreamController<List<int>>();
      isolateChannel.stream = fakeOut.stream;
      // ignore: unawaited_futures
      isolateChannel.fakeIn.controller.stream.first.then((_) {
        var encoded = json.encode({'id': '0'});
        fakeOut.add(utf8.encoder.convert('$encoded\n'));
      });
      server.isolateExited.complete();
      server.listenToOutput();
      await server.stop(timeLimit: const Duration(milliseconds: 1));
      expect(isolate.killed, isFalse);
    });
    test('stopped', () async {
      final fakeOut = StreamController<List<int>>();
      isolateChannel.stream = fakeOut.stream;

      server.isolateExited.complete();
      server.listenToOutput();
      await server.stop(timeLimit: const Duration(milliseconds: 1));
      expect(isolate.killed, isFalse);
    });
    test('kill', () async {
      final fakeOut = StreamController<List<int>>();
      isolateChannel.stream = fakeOut.stream;

      server.listenToOutput();
      await server.stop(timeLimit: const Duration(milliseconds: 10));
      expect(isolate.killed, isTrue);
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

class FakeIsolate implements Isolate {
  bool killed = false;

  @override
  void addErrorListener(SendPort port) => throw UnimplementedError();

  @override
  void addOnExitListener(SendPort port, {Object response}) =>
      throw UnimplementedError();

  @override
  SendPort get controlPort => throw UnimplementedError();

  @override
  String get debugName => throw UnimplementedError();

  @override
  Stream get errors => throw UnimplementedError();

  @override
  Capability get pauseCapability => throw UnimplementedError();

  @override
  void ping(SendPort port,
          {Object response, int priority = Isolate.immediate}) =>
      throw UnimplementedError();

  @override
  void removeErrorListener(SendPort port) => throw UnimplementedError();

  @override
  void removeOnExitListener(SendPort port) => throw UnimplementedError();

  @override
  void resume(Capability capability) => throw UnimplementedError();

  @override
  Capability get terminateCapability => throw UnimplementedError();

  @override
  void kill({int priority = Isolate.beforeNextEvent}) {
    killed = true;
  }

  @override
  Capability pause([Capability resumeCapability]) => throw UnimplementedError();

  @override
  void setErrorsFatal(bool errorsAreFatal) => throw UnimplementedError();
}

class FakeIsolateChannel<T> implements IsolateChannel<T> {
  FakeIsolateInput fakeIn = FakeIsolateInput();

  @override
  StreamChannel<S> cast<S>() => throw UnimplementedError();

  @override
  StreamChannel<T> changeSink(
          StreamSink<T> Function(StreamSink<T> sink) change) =>
      throw UnimplementedError();

  @override
  StreamChannel<T> changeStream(Stream<T> Function(Stream<T> stream) change) =>
      throw UnimplementedError();

  @override
  void pipe(StreamChannel<T> other) => throw UnimplementedError();

  @override
  StreamSink<T> get sink => fakeIn as StreamSink<T>;

  @override
  Stream<T> stream;

  @override
  StreamChannel<S> transform<S>(StreamChannelTransformer<S, T> transformer) =>
      throw UnimplementedError();

  @override
  StreamChannel<T> transformSink(StreamSinkTransformer<T, T> transformer) =>
      throw UnimplementedError();

  @override
  StreamChannel<T> transformStream(StreamTransformer<T, T> transformer) =>
      throw UnimplementedError();
}

class FakeIsolateInput implements IOSink {
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
