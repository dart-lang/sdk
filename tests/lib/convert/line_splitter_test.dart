// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library line_splitter_test;
import "package:expect/expect.dart";
import 'dart:async';
import 'dart:convert';
import 'dart:math' as MATH;


void main() {
  testSimpleConvert();
  testManyLines();
  testReadLine1();
  testReadLine2();
}

void testManyLines() {
  const breaks = const ['\n', '\r\n'];
  int breakIndex = 0;

  var inputs = const ['line1', 'line2', 'long line 3', ' line 4 ', 'l5'];


  var buffer = inputs.fold(new StringBuffer(), (buff, e) {
    buff.write(e);
    buff.write(breaks[breakIndex]);

    breakIndex++;
    breakIndex = breakIndex % breaks.length;

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
  while(index < str.length) {
    var end = MATH.min(str.length, index + chunkSize);

    sink.addSlice(str, index, end, false);
    index += chunkSize;
  }

  sink.close();
  return lines;
}

void testSimpleConvert() {
  var test = """line1
line2
line3""";


  var decoder = new LineSplitter();
  var result = decoder.convert(test);

  Expect.listEquals(['line1', 'line2', 'line3'], result);

  test = "Line1\nLine2\r\nLine3\rLi"
      "ne4\n"
       "\n\n\r\n\r\n\r\r";

  result = decoder.convert(test);

  Expect.listEquals(
      ['Line1', 'Line2', 'Line3', 'Line4', '', '', '', '', '', ''],
      result);
}

void testReadLine1() {
  var controller = new StreamController(sync: true);
  var stream = controller.stream
      .transform(new Utf8Decoder())
      .transform(new LineSplitter());

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

  stream.listen(
      stringData,
      onDone: streamClosed);

  // Note: codeUnits is fine. Text is ASCII.
  controller.add("Line".codeUnits);
  controller.close();
  Expect.isTrue(done, 'should be done by now');
}

void testReadLine2() {
  var controller = new StreamController(sync: true);

  var stream = controller.stream
    .transform(new Utf8Decoder())
    .transform(new LineSplitter());

  var done = false;

  var stage = 0;
  var subStage = 0;
  stream.listen((line) {
      if (stage == 0) {
        if (subStage == 0) {
          Expect.equals("Line1", line);
          subStage++;
        } else if (subStage == 1) {
          Expect.equals("Line2", line);
          subStage++;
        } else if (subStage == 2) {
          Expect.equals("Line3", line);
          subStage = 0;
          stage++;
        } else {
          Expect.fail("Stage 0 failed");
        }
      } else if (stage == 1) {
        if (subStage == 0) {
          Expect.equals("Line4", line);
          subStage = 0;
          stage++;
        } else {
          Expect.fail("Stage 1 failed");
        }
      } else if (stage == 2) {
        if (subStage < 4) {
          // Expect 5 empty lines. As long as the stream is not closed the
          // final \r cannot be interpreted as a end of line.
          Expect.equals("", line);
          subStage++;
        } else if (subStage == 4) {
          Expect.equals("", line);
          subStage = 0;
          stage++;
        } else {
          Expect.fail("Stage 2 failed");
        }
      } else if (stage == 3) {
        if (subStage == 0) {
          Expect.equals("", line);
          stage++;
        } else {
          Expect.fail("Stage 3 failed");
        }
      }
    }, onDone: () {
      Expect.equals(4, stage);
      Expect.equals(0, subStage);
      done = true;
    });

  // Note: codeUnits is fine. Text is ASCII.
  controller.add("Line1\nLine2\r\nLine3\rLi".codeUnits);
  controller.add("ne4\n".codeUnits);
  controller.add("\n\n\r\n\r\n\r\r".codeUnits);
  controller.close();
  Expect.isTrue(done, 'should be done here...');
}
