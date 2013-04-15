// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";
import "dart:utf";

void testUtf8() {
  List<int> data = [0x01,
                    0x7f,
                    0xc2, 0x80,
                    0xdf, 0xbf,
                    0xe0, 0xa0, 0x80,
                    0xef, 0xbf, 0xbf,
                    0xf0, 0x9d, 0x84, 0x9e,
                    0x100, -0x1, -0xFF];
  var controller = new StreamController();
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
  var controller = new StreamController();
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
  var controller = new StreamController();
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
  var controller = new StreamController();
  var stream = controller.stream
      .transform(new StringDecoder())
      .transform(new LineTransformer());

  var stage = 0;

  void stringData(line) {
    var line;
    if (stage == 0) {
      Expect.equals(null, line);
      stage++;
      controller.close();
    } else if (stage == 1) {
      Expect.equals("Line", line);
      stage++;
    }
  }

  void streamClosed() {
    Expect.equals(2, stage);
  }

  stream.listen(
      stringData,
      onDone: streamClosed);

  controller.add("Line".codeUnits);
}

void testReadLine2() {
  var controller = new StreamController();

  var stream = controller.stream
    .transform(new StringDecoder())
    .transform(new LineTransformer());

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
          controller.add("ne4\n".codeUnits);
        } else {
          Expect.fail("Stage 0 failed");
        }
      } else if (stage == 1) {
        if (subStage == 0) {
          Expect.equals("Line4", line);
          subStage = 0;
          stage++;
          controller.add("\n\n\r\n\r\n\r\r".codeUnits);
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
          controller.close();
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
    });

  controller.add("Line1\nLine2\r\nLine3\rLi".codeUnits);
}

class TestException implements Exception {
  TestException();
}

testErrorHandler() {
  var controller = new StreamController();
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

testLatin1EncoderError() {
  List<int> data = [0x01,
                    0x7f,
                    0x44, 0x61, 0x72, 0x74,
                    0x80,
                    0xff,
                    0x100];
  var controller = new StreamController();
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

main() {
  testUtf8();
  testLatin1();
  testAscii();
  testReadLine1();
  testReadLine2();
  testErrorHandler();
  testLatin1EncoderError();
}
