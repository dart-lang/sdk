// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";
import "dart:utf";

void main() {
  testUtf8();
  testLatin1();
  testAscii();
  testReadLine1();
  testReadLine2();
  testErrorHandler();
  testLatin1EncoderError();
}

void testUtf8() {
  List<int> data = [0x01,
                    0x7f,
                    0xc2, 0x80,
                    0xdf, 0xbf,
                    0xe0, 0xa0, 0x80,
                    0xef, 0xbf, 0xbf,
                    0xf0, 0x9d, 0x84, 0x9e,
                    0x100, -0x1, -0xFF];
  var controller = new StreamController(sync: true);
  controller.add(data);
  controller.close();
  var stringStream = controller.stream
    .transform(new StringDecoder(Encoding.UTF_8));
  stringStream.listen(
    (s) {
      Expect.equals(11, s.length);
      Expect.equals(new String.fromCharCodes([0x01]), s[0]);
      Expect.equals(new String.fromCharCodes([0x7f]), s[1]);
      Expect.equals(new String.fromCharCodes([0x80]), s[2]);
      Expect.equals(new String.fromCharCodes([0x7ff]), s[3]);
      Expect.equals(new String.fromCharCodes([0x800]), s[4]);
      Expect.equals(new String.fromCharCodes([0xffff]), s[5]);
      Expect.equals(new String.fromCharCodes([0xffff]), s[5]);

      // Surrogate pair for U+1D11E.
      Expect.equals(new String.fromCharCodes([0xd834, 0xdd1e]),
                    s.substring(6, 8));

      Expect.equals(new String.fromCharCodes(
          [UNICODE_REPLACEMENT_CHARACTER_CODEPOINT,
           UNICODE_REPLACEMENT_CHARACTER_CODEPOINT,
           UNICODE_REPLACEMENT_CHARACTER_CODEPOINT]),
          s.substring(8, 11));
    });
}

void testLatin1() {
  List<int> data = [0x01,
                    0x7f,
                    0x44, 0x61, 0x72, 0x74,
                    0x80,
                    0xff,
                    0x100, -0x1, -0xff];
  var controller = new StreamController(sync: true);
  controller.add(data);
  controller.close();
  var stream = controller.stream
    .transform(new StringDecoder(Encoding.ISO_8859_1));
  stream.listen((s) {
    Expect.equals(11, s.length);
    Expect.equals(new String.fromCharCodes([0x01]), s[0]);
    Expect.equals(new String.fromCharCodes([0x7f]), s[1]);
    Expect.equals("Dart", s.substring(2, 6));
    Expect.equals(new String.fromCharCodes([0x80]), s[6]);
    Expect.equals(new String.fromCharCodes([0xff]), s[7]);
    Expect.equals('???', s.substring(8, 11));
  });
}

void testAscii() {
  List<int> data = [0x01,
                    0x44, 0x61, 0x72, 0x74,
                    0x7f,
                    0xf4, 0x100, -0x1, -0xff];
  var controller = new StreamController(sync: true);
  controller.add(data);
  controller.close();
  var stream = controller.stream
    .transform(new StringDecoder(Encoding.ASCII));
  stream.listen((s) {
    Expect.equals(10, s.length);
    Expect.equals(new String.fromCharCodes([0x01]), s[0]);
    Expect.equals("Dart", s.substring(1, 5));
    Expect.equals(new String.fromCharCodes([0x7f]), s[5]);
    Expect.equals('????', s.substring(6, 10));
  });
}

void testReadLine1() {
  var controller = new StreamController(sync: true);
  var stream = controller.stream
      .transform(new StringDecoder())
      .transform(new LineTransformer());

  var stage = 0;

  void stringData(line) {
    Expect.equals(stage, 0);
    Expect.equals("Line", line);
    stage++;
  }

  void streamClosed() {
    Expect.equals(1, stage);
  }

  stream.listen(
      stringData,
      onDone: streamClosed);

  // Note: codeUnits is fine. Text is ASCII.
  controller.add("Line".codeUnits);
  controller.close();
  Expect.equals(1, stage);
}

void testReadLine2() {
  var controller = new StreamController(sync: true);

  var stream = controller.stream
    .transform(new StringDecoder())
    .transform(new LineTransformer());

  var expectedLines = ['Line1', 'Line2','Line3', 'Line4',
                       '', '', '', '', '', '',
                       'Line5', 'Line6'];

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

class TestException implements Exception {
  TestException();
}

void testErrorHandler() {
  var controller = new StreamController(sync: true);
  var errors = 0;
  var stream = controller.stream
    .transform(new StringDecoder())
    .transform(new LineTransformer());
  stream.listen(
      (_) {},
      onDone: () {
        Expect.equals(1, errors);
      },
      onError: (error) {
        errors++;
        Expect.isTrue(error is TestException);
      });
  controller.addError(new TestException());
  controller.close();
}

void testLatin1EncoderError() {
  List<int> data = [0x01,
                    0x7f,
                    0x44, 0x61, 0x72, 0x74,
                    0x80,
                    0xff,
                    0x100];
  var controller = new StreamController(sync: true);
  controller.add(new String.fromCharCodes(data));
  controller.close();
  var stream = controller.stream
    .transform(new StringEncoder(Encoding.ISO_8859_1));
  stream.listen(
    (s) {
      Expect.fail("data not expected");
    },
    onError: (error) {
      Expect.isTrue(error is FormatException);
    });

}
