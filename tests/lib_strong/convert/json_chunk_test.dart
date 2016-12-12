// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_test;

import "package:expect/expect.dart";
import "dart:convert";

bool badFormat(e) => e is FormatException;

jsonTest(testName, expect, action(sink)) {
  var sink = new ChunkedConversionSink.withCallback((values) {
    var value = values[0];
    Expect.equals(expect, value, "$testName:$value");
  });
  var decoderSink = JSON.decoder.startChunkedConversion(sink);
  action(decoderSink);
}

jsonThrowsTest(testName, action(sink)) {
  var sink = new ChunkedConversionSink.withCallback((values) {
    Expect.fail("Should have thrown: $testName");
  });
  var decoderSink = JSON.decoder.startChunkedConversion(sink);
  Expect.throws(() { action(decoderSink); }, (e) => e is FormatException,
                testName);
}

main() {
  testNumbers();
  testStrings();
  testKeywords();
}

void testStrings() {
  var s = r'"abc\f\n\r\t\b\"\/\\\u0001\u9999\uffff"';
  var expected = "abc\f\n\r\t\b\"\/\\\u0001\u9999\uffff";
  for (var i = 1; i < s.length - 1; i++) {
    var s1 = s.substring(0, i);
    var s2 = s.substring(i);
    jsonTest("$s1|$s2", expected, (sink) {
      sink.add(s1);
      sink.add(s2);
      sink.close();
    });
    jsonTest("$s1|$s2", expected, (sink) {
      sink.addSlice(s, 0, i, false);
      sink.addSlice(s, i, s.length, true);
    });
    for (var j = i; j < s.length - 1; j++) {
      var s2a = s.substring(i, j);
      var s2b = s.substring(j);
      jsonTest("$s1|$s2a|$s2b", expected, (sink) {
        sink.add(s1);
        sink.add(s2a);
        sink.add(s2b);
        sink.close();
      });
    }
  }
}

void testNumbers() {
  void testNumber(number) {
    var expected = num.parse(number);
    for (int i = 1; i < number.length - 1; i++) {
      var p1 = number.substring(0, i);
      var p2 = number.substring(i);
      jsonTest("$p1|$p2", expected, (sink) {
        sink.add(p1);
        sink.add(p2);
        sink.close();
      });

      jsonTest("$p1|$p2/slice", expected, (sink) {
        sink.addSlice(number, 0, i, false);
        sink.addSlice(number, i, number.length, true);
      });

      for (int j = i; j < number.length - 1; j++) {
        var p2a = number.substring(i, j);
        var p2b = number.substring(j);
        jsonTest("$p1|$p2a|$p2b", expected, (sink) {
          sink.add(p1);
          sink.add(p2a);
          sink.add(p2b);
          sink.close();
        });
      }
    }
  }
  for (var sign in ["-", ""]) {
    for (var intPart in ["0", "1", "99"]) {
      for (var decimalPoint in [".", ""]) {
        for (var decimals in decimalPoint.isEmpty ? [""] : ["0", "99"]) {
          for (var e in ["e", "e-", "e+", ""]) {
            for (var exp in e.isEmpty ? [""] : ["0", "2", "22", "34"]) {
              testNumber("$sign$intPart$decimalPoint$decimals$e$exp");
            }
          }
        }
      }
    }
  }

  void negativeTest(number) {
    for (int i = 1; i < number.length - 1; i++) {
      var p1 = number.substring(0, i);
      var p2 = number.substring(i);
      jsonThrowsTest("$p1|$p2", (sink) {
        sink.add(p1);
        sink.add(p2);
        sink.close();
      });

      jsonThrowsTest("$p1|$p2/slice", (sink) {
        sink.addSlice(number, 0, i, false);
        sink.addSlice(number, i, number.length, true);
      });

      for (int j = i; j < number.length - 1; j++) {
        var p2a = number.substring(i, j);
        var p2b = number.substring(j);
        jsonThrowsTest("$p1|$p2a|$p2b", (sink) {
          sink.add(p1);
          sink.add(p2a);
          sink.add(p2b);
          sink.close();
        });
      }
    }
  }

  negativeTest("+1e");
  negativeTest("-00");
  negativeTest("01");
  negativeTest(".1");
  negativeTest("0.");
  negativeTest("0.e1");
  negativeTest("1e");
  negativeTest("1e+");
  negativeTest("1e-");
}

void testKeywords() {
  for (var expected in [null, true, false]) {
    var s = "$expected";
    for (int i = 1; i < s.length - 1; i++) {
      var s1 = s.substring(0, i);
      var s2 = s.substring(i);
      jsonTest("$s1|$s2", expected, (sink) {
        sink.add(s1);
        sink.add(s2);
        sink.close();
      });
      jsonTest("$s1|$s2", expected, (sink) {
        sink.addSlice(s, 0, i, false);
        sink.addSlice(s, i, s.length, true);
      });
      for (var j = i; j < s.length - 1; j++) {
        var s2a = s.substring(i, j);
        var s2b = s.substring(j);
        jsonTest("$s1|$s2a|$s2b", expected, (sink) {
          sink.add(s1);
          sink.add(s2a);
          sink.add(s2b);
          sink.close();
        });
      }
    }
  }
}
