// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library line_splitter_test;

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:convert';
import 'dart:math' as MATH;

const lineTerminators = const ['\n', '\r', '\r\n'];

void main() {
  testSimpleConvert();
  testSplit();
  testSplitWithOffsets();
  testManyLines();
  testReadLine1();
  testReadLine2();
  testChunkedConversion();
}

void testManyLines() {
  int breakIndex = 0;

  var inputs = const ['line1', 'line2', 'long line 3', ' line 4 ', 'l5'];

  var buffer = inputs.fold(new StringBuffer(), (buff, e) {
    buff.write(e);
    buff.write(lineTerminators[breakIndex]);

    breakIndex++;
    breakIndex = breakIndex % lineTerminators.length;

    return buff;
  });

  var foo = _getLinesSliced(buffer.toString());
  Expect.equals(inputs.join(), foo);
}

String _getLinesSliced(String str) {
  String lines;
  var stringSink =
      new StringConversionSink.withCallback((result) => lines = result);
  var sink = new LineSplitter().startChunkedConversion(stringSink);

  const chunkSize = 3;
  var index = 0;
  while (index < str.length) {
    var end = MATH.min(str.length, index + chunkSize);

    sink.addSlice(str, index, end, false);
    index += chunkSize;
  }

  sink.close();
  return lines;
}

void testSimpleConvert() {
  var decoder = new LineSplitter();
  for (var lf in lineTerminators) {
    var test = "line1${lf}line2${lf}line3";

    var result = decoder.convert(test);

    Expect.listEquals(['line1', 'line2', 'line3'], result);
  }

  var test = "Line1\nLine2\r\nLine3\rLine4\n\n\n\r\n\r\n\r\r";
  var result = decoder.convert(test);

  Expect.listEquals(
      ['Line1', 'Line2', 'Line3', 'Line4', '', '', '', '', '', ''], result);
}

void testReadLine1() {
  var controller = new StreamController(sync: true);
  var stream =
      controller.stream.transform(UTF8.decoder).transform(const LineSplitter());

  var stage = 0;
  var done = false;

  void stringData(line) {
    Expect.equals(stage, 0);
    Expect.equals("Line", line);
    stage++;
  }

  void streamClosed() {
    Expect.equals(1, stage);
    done = true;
  }

  stream.listen(stringData, onDone: streamClosed);

  // Note: codeUnits is fine. Text is ASCII.
  controller.add("Line".codeUnits);
  controller.close();
  Expect.isTrue(done, 'should be done by now');
}

void testReadLine2() {
  var controller = new StreamController(sync: true);

  var stream =
      controller.stream.transform(UTF8.decoder).transform(const LineSplitter());

  var expectedLines = [
    'Line1',
    'Line2',
    'Line3',
    'Line4',
    '',
    '',
    '',
    '',
    '',
    '',
    'Line5',
    'Line6'
  ];

  var index = 0;

  stream.listen((line) {
    Expect.equals(expectedLines[index++], line);
  });

  // Note: codeUnits is fine. Text is ASCII.
  controller.add("Line1\nLine2\r\nLine3\rLi".codeUnits);
  controller.add("ne4\n".codeUnits);
  controller.add("\n\n\r\n\r\n\r\r".codeUnits);
  controller.add("Line5\r".codeUnits);
  controller.add("\nLine6\n".codeUnits);
  controller.close();
  Expect.equals(expectedLines.length, index);
}

void testSplit() {
  for (var lf in lineTerminators) {
    var test = "line1${lf}line2${lf}line3";
    var result = LineSplitter.split(test).toList();
    Expect.listEquals(['line1', 'line2', 'line3'], result);
  }

  var test = "Line1\nLine2\r\nLine3\rLine4\n\n\n\r\n\r\n\r\r";
  var result = LineSplitter.split(test).toList();

  Expect.listEquals(
      ['Line1', 'Line2', 'Line3', 'Line4', '', '', '', '', '', ''], result);
}

void testSplitWithOffsets() {
  for (var lf in lineTerminators) {
    var test = "line1${lf}line2${lf}line3";
    var i2 = 5 + lf.length; // index of "line2".
    Expect.equals(5 + lf.length, i2);

    var result = LineSplitter.split(test, 4).toList();
    Expect.listEquals(['1', 'line2', 'line3'], result);

    result = LineSplitter.split(test, 5).toList();
    Expect.listEquals(['', 'line2', 'line3'], result);

    result = LineSplitter.split(test, i2).toList();
    Expect.listEquals(['line2', 'line3'], result);

    result = LineSplitter.split(test, 0, i2 + 2).toList();
    Expect.listEquals(['line1', 'li'], result);

    result = LineSplitter.split(test, i2, i2 + 5).toList();
    Expect.listEquals(['line2'], result);
  }

  var test = "Line1\nLine2\r\nLine3\rLine4\n\n\n\r\n\r\n\r\r";

  var result = LineSplitter.split(test).toList();

  Expect.listEquals(
      ['Line1', 'Line2', 'Line3', 'Line4', '', '', '', '', '', ''], result);

  test = "a\n\nb\r\nc\n\rd\r\re\r\n\nf\r\n";
  result = LineSplitter.split(test).toList();
  Expect.listEquals(["a", "", "b", "c", "", "d", "", "e", "", "f"], result);
}

void testChunkedConversion() {
  // Test any split of this complex string.
  var test = "a\n\nb\r\nc\n\rd\r\re\r\n\nf\rg\nh\r\n";
  var result = ["a", "", "b", "c", "", "d", "", "e", "", "f", "g", "h"];
  for (int i = 0; i < test.length; i++) {
    var output = [];
    var splitter = new LineSplitter();
    var outSink = new ChunkedConversionSink.withCallback(output.addAll);
    var sink = splitter.startChunkedConversion(outSink);
    sink.addSlice(test, 0, i, false);
    sink.addSlice(test, i, test.length, false);
    sink.close();
    Expect.listEquals(result, output);
  }

  // Test the string split into three parts in any way.
  for (int i = 0; i < test.length; i++) {
    for (int j = i; j < test.length; j++) {
      var output = [];
      var splitter = new LineSplitter();
      var outSink = new ChunkedConversionSink.withCallback(output.addAll);
      var sink = splitter.startChunkedConversion(outSink);
      sink.addSlice(test, 0, i, false);
      sink.addSlice(test, i, j, false);
      sink.addSlice(test, j, test.length, true);
      Expect.listEquals(result, output);
    }
  }
}
