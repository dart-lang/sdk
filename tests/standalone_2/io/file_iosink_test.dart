// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/// Test the [IOSink] returned by [File.openWrite].

import "dart:async";
import "dart:convert";
import 'dart:collection';
import "dart:io";
import 'dart:typed_data';

import "package:expect/expect.dart";

/// A list that throws when it's data is retrieved. Useful in simulating write
/// failures.
class BrokenList extends Object with ListMixin<int> implements List<int> {
  String _message;

  BrokenList(this._message, this.length);

  int length = 10;

  void operator []=(int index, int value) {
    throw UnsupportedError('[$index] = $value');
  }

  operator [](int index) => throw FileSystemException(_message);
}

Future<void> testWriteAllEmptyIterator(Directory tmpDir) async {
  final file = File('${tmpDir.path}/write_all_empty_iterator');

  final sink = file.openWrite();
  sink.writeAll([]);
  await sink.close();
  Expect.equals('', file.readAsStringSync());
}

Future<void> testWriteAllEmptyIteratorWithSep(Directory tmpDir) async {
  final file = File('${tmpDir.path}/write_all_empty_iterator_with_sep');

  final sink = file.openWrite();
  sink.writeAll([], ',');
  await sink.close();
  Expect.equals('', file.readAsStringSync());
}

Future<void> testWriteAllOneElementIterator(Directory tmpDir) async {
  final file = File('${tmpDir.path}/write_one_element_iterator');

  final sink = file.openWrite();
  sink.writeAll(['hello']);
  await sink.close();
  Expect.equals('hello', file.readAsStringSync());
}

Future<void> testWriteAllOneElementIteratorWithSep(Directory tmpDir) async {
  final file = File('${tmpDir.path}/write_one_element_iterator_with_sep');

  final sink = file.openWrite();
  sink.writeAll(['hello'], ',');
  await sink.close();
  Expect.equals('hello', file.readAsStringSync());
}

Future<void> testWriteAllTwoElementIterator(Directory tmpDir) async {
  final file = File('${tmpDir.path}/write_two_element_iterator');

  final sink = file.openWrite();
  sink.writeAll(['hello', 'world']);
  await sink.close();
  Expect.equals('helloworld', file.readAsStringSync());
}

Future<void> testWriteAllTwoElementIteratorWithSep(Directory tmpDir) async {
  final file = File('${tmpDir.path}/write_two_element_iterator_with_sep');

  final sink = file.openWrite();
  sink.writeAll(['hello', 'world'], ',');
  await sink.close();
  Expect.equals('hello,world', file.readAsStringSync());
}

Future<void> testWriteln(Directory tmpDir) async {
  final file = File('${tmpDir.path}/test_writeln');

  final sink = file.openWrite();
  sink.writeln();
  await sink.close();
  Expect.equals('\n', file.readAsStringSync());
}

Future<void> testWritelnWithArg(Directory tmpDir) async {
  final file = File('${tmpDir.path}/test_writeln_with_arg');

  final sink = file.openWrite();
  sink.writeln('Hello World!');
  await sink.close();
  Expect.equals('Hello World!\n', file.readAsStringSync());
}

Future<void> testWriteEncoded(Directory tmpDir) async {
  final file = File('${tmpDir.path}/test_writeln_with_arg');

  final sink = file.openWrite();
  sink.encoding = latin1;
  sink.write('Allô');
  await sink.close();
  Expect.equals('Allô', file.readAsStringSync(encoding: latin1));
}

Future<void> testFlushWithoutWrite(Directory tmpDir) async {
  final file = File('${tmpDir.path}/small_write');

  final sink = file.openWrite();
  await sink.close();
  Expect.equals('', file.readAsStringSync());
}

Future<void> testSmallWrite(Directory tmpDir) async {
  final file = File('${tmpDir.path}/small_write');

  final sink = file.openWrite();
  sink.writeln('Hello World!');
  await sink.close();

  Expect.equals('Hello World!\n', file.readAsStringSync());
}

Future<void> testSmallWriteAfterFlush(Directory tmpDir) async {
  final file = File('${tmpDir.path}/small_write_after_flush');

  final sink = file.openWrite();
  sink.writeln('Hello World!');
  await sink.flush();
  sink.writeln('How are you?');
  await sink.close();

  Expect.listEquals(['Hello World!', 'How are you?'], file.readAsLinesSync());
}

Future<void> testSmallWriteAfterClose(Directory tmpDir) async {
  final file = File('${tmpDir.path}/small_write_after_flush');

  final sink = file.openWrite();
  await sink.close();

  Expect.throws(() => sink.writeln('Hello World!'), (e) => e is StateError);
}

Future<void> testManySmallWrites(Directory tmpDir) async {
  final file = File('${tmpDir.path}/many_small_writes');

  final sink = file.openWrite();

  final data = List.generate(10000, (l) => '{l}');

  data.forEach(sink.writeln);
  await sink.close();

  Expect.listEquals(data, file.readAsLinesSync());
}

Future<void> testLargeWriteAfterSmallWrite(Directory tmpDir) async {
  final file = File('${tmpDir.path}/large_write_after_small_write');

  final sink = file.openWrite();
  sink.writeln('Hello');
  sink.writeln('World' * 100000);
  await sink.close();

  Expect.listEquals(['Hello', 'World' * 100000], file.readAsLinesSync());
}

Future<void> testAddStream(Directory tmpDir) async {
  final file = File('${tmpDir.path}/add_stream');

  final sink = file.openWrite();
  final data = [
    [1],
    [2, 3],
    [4, 5, 6],
    [7, 8, 9, 10]
  ];
  await sink.addStream(Stream.fromIterable(data));
  await sink.close();

  Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], file.readAsBytesSync());
}

Future<void> testMultipleAddStream(Directory tmpDir) async {
  final file = File('${tmpDir.path}/add_stream');

  final sink = file.openWrite();
  final data1 = [
    [1],
    [2, 3],
    [4, 5, 6],
    [7, 8, 9, 10]
  ];
  final data2 = [
    [11],
    [12, 13],
    [14, 15, 16],
    [17, 18, 19, 20]
  ];
  await sink.addStream(Stream.fromIterable(data1));
  await sink.addStream(Stream.fromIterable(data2));
  await sink.close();

  Expect.listEquals(
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
      file.readAsBytesSync());
}

Future<void> testAddDuringAddStream(Directory tmpDir) async {
  final file = File('${tmpDir.path}/add_during_add_stream');

  final sink = file.openWrite();
  final data = [
    [1],
    [2, 3],
    [4, 5, 6],
    [7, 8, 9, 10]
  ];
  final add = sink.addStream(Stream.fromIterable(data));
  try {
    sink.add([1]);
    Expect.fail('expected exception');
  } on StateError catch (e) {
    Expect.contains('add_during_add_stream is bound to a stream', e.message);
  }

  await add;
  await sink.close();
  Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], file.readAsBytesSync());
}

Future<void> testAddErrorDuringAddStream(Directory tmpDir) async {
  final file = File('${tmpDir.path}/add_error_during_add_stream');

  final sink = file.openWrite();
  final data = [
    [1],
    [2, 3],
    [4, 5, 6],
    [7, 8, 9, 10]
  ];
  final add = sink.addStream(Stream.fromIterable(data));
  try {
    sink.addError(FormatException());
    Expect.fail('expected exception');
  } on StateError catch (e) {
    Expect.contains(
        'add_error_during_add_stream is bound to a stream', e.message);
  }

  await add;
  await sink.close();
  Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], file.readAsBytesSync());
}

Future<void> testAddStreamDuringAddStream(Directory tmpDir) async {
  final file = File('${tmpDir.path}/add_stream_during_add_stream');

  final sink = file.openWrite();
  final data = [
    [1],
    [2, 3],
    [4, 5, 6],
    [7, 8, 9, 10]
  ];
  final add = sink.addStream(Stream.fromIterable(data));
  try {
    await sink.addStream(Stream.fromIterable([
      [11, 12]
    ]));
    Expect.fail('expected exception');
  } on StateError catch (e) {
    Expect.contains(
        'add_stream_during_add_stream is bound to a stream', e.message);
  }

  await add;
  await sink.close();
  Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], file.readAsBytesSync());
}

Future<void> testCloseDuringAddStream(Directory tmpDir) async {
  final file = File('${tmpDir.path}/close_during_add_stream');

  final sink = file.openWrite();
  final data = [
    [1],
    [2, 3],
    [4, 5, 6],
    [7, 8, 9, 10]
  ];
  final add = sink.addStream(Stream.fromIterable(data));
  try {
    await sink.close();
    Expect.fail('expected exception');
  } on StateError catch (e) {
    Expect.contains('close_during_add_stream is bound to a stream', e.message);
  }

  await add;
  await sink.close();
  Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], file.readAsBytesSync());
}

Future<void> testFlushDuringAddStream(Directory tmpDir) async {
  final file = File('${tmpDir.path}/flush_during_add_stream');

  final sink = file.openWrite();
  final data = [
    [1],
    [2, 3],
    [4, 5, 6],
    [7, 8, 9, 10]
  ];
  final add = sink.addStream(Stream.fromIterable(data));
  try {
    await sink.flush();
    Expect.fail('expected exception');
  } on StateError catch (e) {
    Expect.contains('flush_during_add_stream is bound to a stream', e.message);
  }

  await add;
  await sink.close();
  Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], file.readAsBytesSync());
}

Future<void> testAddDuringClose(Directory tmpDir) async {
  final file = File('${tmpDir.path}/add_during_close');

  final sink = file.openWrite();
  final close = sink.close();

  try {
    sink.writeln("Hello");
  } on StateError catch (e) {
    Expect.contains('add_during_close is closed', e.message);
  }
  await close;
}

Future<void> testAddErrorDuringClose(Directory tmpDir) async {
  final file = File('${tmpDir.path}/add_error_during_close');

  final sink = file.openWrite();
  final close = sink.close();

  try {
    sink.addError(FormatException());
  } on StateError catch (e) {
    Expect.contains('add_error_during_close is closed', e.message);
  }
  await close;
}

Future<void> testAddStreamDuringClose(Directory tmpDir) async {
  final file = File('${tmpDir.path}/add_stream_during_close');

  final sink = file.openWrite();
  final close = sink.close();

  try {
    await sink.addStream(Stream.fromIterable([
      [1]
    ]));
  } on StateError catch (e) {
    Expect.contains('add_stream_during_close is closed', e.message);
  }
  await close;
}

Future<void> testCloseDuringClose(Directory tmpDir) async {
  final file = File('${tmpDir.path}/close_during_close');

  final sink = file.openWrite();
  final close = sink.close();
  await sink.close();
  await close;
}

Future<void> testFlushDuringClose(Directory tmpDir) async {
  final file = File('${tmpDir.path}/flush_during_close');

  final sink = file.openWrite();
  final close = sink.close();

  try {
    await sink.flush();
  } on StateError catch (e) {
    Expect.contains('flush_during_close is closed', e.message);
  }

  await close;
}

Future<void> testFailedWrite(Directory tmpDir) async {
  final file = File('${tmpDir.path}/failed_write');

  final sink = file.openWrite();
  sink.add(BrokenList('testFailedWrite', 100000));
  try {
    await sink.flush();
    Expect.fail('expected exception');
  } on FileSystemException catch (e) {
    Expect.equals('testFailedWrite', e.message);
  }
  try {
    await sink.close();
    Expect.fail('expected exception');
  } on FileSystemException catch (e) {}
  Expect.listEquals([], file.readAsBytesSync());
}

Future<void> testAddAfterFailedWrite(Directory tmpDir) async {
  final file = File('${tmpDir.path}/add_after_failed_write');

  final sink = file.openWrite();
  sink.add(BrokenList('testAddAfterFailedWrite', 100000));

  try {
    await sink.flush();
    Expect.fail('expected exception');
  } on FileSystemException catch (e) {}

  sink.add([1, 2, 3]);
  try {
    await sink.flush();
    Expect.fail('expected exception');
  } on FileSystemException catch (e) {}

  try {
    await sink.close();
    Expect.fail('expected exception');
  } on FileSystemException catch (e) {}
  Expect.listEquals([], file.readAsBytesSync());
}

Future<void> testFailedWriteAfterAdd(Directory tmpDir) async {
  final file = File('${tmpDir.path}/failed_write_after_add');

  final sink = file.openWrite();
  sink.add(<int>[1, 2, 3, 4, 5]);
  sink.add(BrokenList('testFailedWriteAfterAdd', 100000));

  try {
    await sink.close();
    Expect.fail('expected exception');
  } on FileSystemException catch (e) {}
  Expect.listEquals([1, 2, 3, 4, 5], file.readAsBytesSync());
}

Future<void> testFailedWriteAfterTwoAdds(Directory tmpDir) async {
  final file = File('${tmpDir.path}/failed_write_after_add');

  final sink = file.openWrite();
  sink.add(<int>[1, 2, 3, 4, 5]);
  sink.add(<int>[6, 7, 8, 9]);
  sink.add(BrokenList('testFailedWriteAfterAdd', 100000));

  try {
    await sink.close();
    Expect.fail('expected exception');
  } on FileSystemException catch (e) {}
  Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9], file.readAsBytesSync());
}

Future<void> testFlushUnawaitedAddStream(Directory tmpDir) async {
  final file = File('${tmpDir.path}/flush_unawaited_add_stream');

  final sink = file.openWrite();

  final controller = StreamController<List<int>>();
  sink.addStream(controller.stream);
  controller.add(<int>[1, 2, 3, 4, 5]);
  await controller.close();
  await sink.flush();

  Expect.listEquals([1, 2, 3, 4, 5], file.readAsBytesSync());
  await sink.close();
}

Future<void> testUnawaitedAddStream(Directory tmpDir) async {
  final file = File('${tmpDir.path}/unawaited_add_stream');

  final sink = file.openWrite();

  final controller = StreamController<List<int>>();
  sink.addStream(controller.stream);
  controller.add(<int>[1, 2, 3, 4, 5]);
  controller.add(<int>[6, 7, 8, 9]);
  await controller.close();

  Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9], file.readAsBytesSync());
  await sink.close();
}

Future<void> testAddIsEager(Directory tmpDir) async {
  // Tests that calling `IOSink.add` results in a write *before* `close` or
  // `flush` are called.
  final file = File('${tmpDir.path}/add_is_eager');

  final sink = file.openWrite();

  sink.add(<int>[1, 2, 3, 4, 5]);
  sink.add(<int>[6, 7, 8, 9]);
  await Future.delayed(const Duration(seconds: 2));

  Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9], file.readAsBytesSync());
  await sink.close();
}

Future<void> testAddStreamIsEager(Directory tmpDir) async {
  // Tests that calling `IOSink.addStream` results in writes *before* the
  // stream is closed.
  final file = File('${tmpDir.path}/add_is_eager');

  final sink = file.openWrite();

  final controller = StreamController<List<int>>();
  sink.addStream(controller.stream);
  controller.add(<int>[1, 2, 3, 4, 5]);
  controller.add(<int>[6, 7, 8, 9]);
  await Future.delayed(const Duration(seconds: 2));

  Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8, 9], file.readAsBytesSync());
  await controller.close();
  await sink.close();
}

void main() async {
  final tmpDir = Directory.systemTemp.createTempSync('file_iosink_tests');
  try {
    await testWriteAllEmptyIterator(tmpDir);
    await testWriteAllEmptyIteratorWithSep(tmpDir);
    await testWriteAllOneElementIterator(tmpDir);
    await testWriteAllOneElementIteratorWithSep(tmpDir);
    await testWriteAllTwoElementIterator(tmpDir);
    await testWriteAllTwoElementIteratorWithSep(tmpDir);

    await testWriteln(tmpDir);
    await testWritelnWithArg(tmpDir);

    await testWriteEncoded(tmpDir);

    await testFlushWithoutWrite(tmpDir);
    await testSmallWrite(tmpDir);
    await testSmallWriteAfterFlush(tmpDir);
    await testSmallWriteAfterClose(tmpDir);
    await testManySmallWrites(tmpDir);
    await testLargeWriteAfterSmallWrite(tmpDir);

    await testAddStream(tmpDir);
    await testMultipleAddStream(tmpDir);
    await testAddDuringAddStream(tmpDir);
    await testAddErrorDuringAddStream(tmpDir);
    await testAddStreamDuringAddStream(tmpDir);
    await testCloseDuringAddStream(tmpDir);
    await testFlushDuringAddStream(tmpDir);

    await testAddDuringClose(tmpDir);
    await testAddErrorDuringClose(tmpDir);
    await testAddStreamDuringClose(tmpDir);
    await testCloseDuringClose(tmpDir);
    await testFlushDuringClose(tmpDir);

    await testFailedWrite(tmpDir);
    await testAddAfterFailedWrite(tmpDir);
    await testFailedWriteAfterAdd(tmpDir);
    await testFailedWriteAfterTwoAdds(tmpDir);
    await testFlushUnawaitedAddStream(tmpDir);
    await testUnawaitedAddStream(tmpDir);
    await testAddIsEager(tmpDir);
    await testAddStreamIsEager(tmpDir);
  } finally {
    tmpDir.deleteSync(recursive: true);
  }
}
