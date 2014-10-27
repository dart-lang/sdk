// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import "package:expect/expect.dart";
import "dart:convert";
import "unicode_tests.dart" show UNICODE_TESTS;

bool badFormat(e) => e is FormatException;

main() {
  testNumbers();
  testStrings();
  testKeywords();
  testAll();
  testMalformed();
  testUnicodeTests();
}

// Create an UTF-8 sink from a chunked JSON decoder, then let [action]
// put data into it, and check that what comes out is equal to [expect].
void jsonTest(testName, expect, action(sink), [bool allowMalformed = false]) {
  jsonParse(testName, (value) {
    Expect.equals(expect, value, "$testName:$value");
  }, action, allowMalformed);
}

void jsonParse(testName, check, action, [bool allowMalformed = false]) {
  var sink = new ChunkedConversionSink.withCallback((values) {
    var value = values[0];
    check(value);
  });
  var decoderSink = JSON.decoder.startChunkedConversion(sink)
                                .asUtf8Sink(allowMalformed);
  try {
    action(decoderSink);
  } on FormatException catch (e, s) {
    print("Source: ${e.source} @ ${e.offset}");
    Expect.fail("Unexpected throw($testName): $e\n$s");
  }
}

void testStrings() {
  // String literal containing characters, all escape types,
  // and a number of UTF-8 encoded characters.
  var s = r'"abc\f\ndef\r\t\b\"\/\\\u0001\u9999\uffff'
           '\x7f\xc2\x80\xdf\xbf\xe0\xa0\x80\xef\xbf\xbf'
           '\xf0\x90\x80\x80\xf4\x8f\xbf\xbf"';  // UTF-8.
  var expected = "abc\f\ndef\r\t\b\"\/\\\u0001\u9999\uffff"
                 "\x7f\x80\u07ff\u0800\uffff"
                 "\u{10000}\u{10ffff}";
  for (var i = 1; i < s.length - 1; i++) {
    var s1 = s.substring(0, i);
    var s2 = s.substring(i);
    jsonTest("$s1|$s2-$i", expected, (sink) {
      sink.add(s1.codeUnits);
      sink.add(s2.codeUnits);
      sink.close();
    });
    jsonTest("$s1|$s2-$i-slice", expected, (sink) {
      sink.addSlice(s.codeUnits, 0, i, false);
      sink.addSlice(s.codeUnits, i, s.length, true);
    });
    for (var j = i; j < s.length - 1; j++) {
      var s2a = s.substring(i, j);
      var s2b = s.substring(j);
      jsonTest("$s1|$s2a|$s2b-$i-$j", expected, (sink) {
        sink.add(s1.codeUnits);
        sink.add(s2a.codeUnits);
        sink.add(s2b.codeUnits);
        sink.close();
      });
    }
  }
}

void testNumbers() {
  for (var number in ["-0.12e-12", "-34.12E+12", "0.0e0", "9.9E9", "0", "9"
                      "1234.56789123456701418035663664340972900390625",
                      "1.2345678912345671e-14",
                      "99999999999999999999"]) {
    var expected = num.parse(number);
    for (int i = 1; i < number.length - 1; i++) {
      var p1 = number.substring(0, i);
      var p2 = number.substring(i);
      jsonTest("$p1|$p2", expected, (sink) {
        sink.add(p1.codeUnits);
        sink.add(p2.codeUnits);
        sink.close();
      });

      jsonTest("$p1|$p2/slice", expected, (sink) {
        sink.addSlice(number.codeUnits, 0, i, false);
        sink.addSlice(number.codeUnits, i, number.length, true);
      });

      for (int j = i; j < number.length - 1; j++) {
        var p2a = number.substring(i, j);
        var p2b = number.substring(j);
        jsonTest("$p1|$p2a|$p2b", expected, (sink) {
          sink.add(p1.codeUnits);
          sink.add(p2a.codeUnits);
          sink.add(p2b.codeUnits);
          sink.close();
        });
      }
    }
  }
}

// Test that `null`, `true`, and `false` keywords are decoded correctly.
void testKeywords() {
  for (var expected in [null, true, false]) {
    var s = "$expected";
    for (int i = 1; i < s.length - 1; i++) {
      var s1 = s.substring(0, i);
      var s2 = s.substring(i);
      jsonTest("$s1|$s2", expected, (sink) {
        sink.add(s1.codeUnits);
        sink.add(s2.codeUnits);
        sink.close();
      });
      jsonTest("$s1|$s2", expected, (sink) {
        sink.addSlice(s.codeUnits, 0, i, false);
        sink.addSlice(s.codeUnits, i, s.length, true);
      });
      for (var j = i; j < s.length - 1; j++) {
        var s2a = s.substring(i, j);
        var s2b = s.substring(j);
        jsonTest("$s1|$s2a|$s2b", expected, (sink) {
          sink.add(s1.codeUnits);
          sink.add(s2a.codeUnits);
          sink.add(s2b.codeUnits);
          sink.close();
        });
      }
    }
  }
}

// Tests combinations of numbers, strings and keywords.
void testAll() {
  var s = r'{"":[true,false,42, -33e-3,null,"\u0080"], "z": 0}';
  bool check(o) {
    if (o is Map) {
      Expect.equals(2, o.length);
      Expect.equals(0, o["z"]);
      var v = o[""];
      if (v is List) {
        Expect.listEquals([true, false, 42, -33e-3, null, "\u0080"], v);
      } else {
        Expect.fail("Expected list, found ${v.runtimeType}");
      }
    } else {
      Expect.fail("Expected map, found ${o.runtimeType}");
    }
  }
  for (var i = 1; i < s.length - 1; i++) {
  var s1 = s.substring(0, i);
  var s2 = s.substring(i);
  jsonParse("$s1|$s2-$i", check, (sink) {
    sink.add(s1.codeUnits);
    sink.add(s2.codeUnits);
    sink.close();
  });
  jsonParse("$s1|$s2-$i-slice", check, (sink) {
    sink.addSlice(s.codeUnits, 0, i, false);
    sink.addSlice(s.codeUnits, i, s.length, true);
  });
  for (var j = i; j < s.length - 1; j++) {
    var s2a = s.substring(i, j);
    var s2b = s.substring(j);
    jsonParse("$s1|$s2a|$s2b-$i-$j", check, (sink) {
      sink.add(s1.codeUnits);
      sink.add(s2a.codeUnits);
      sink.add(s2b.codeUnits);
      sink.close();
    });
  }
}

}

// Check that [codes] decode to [expect] when allowing malformed UTF-8,
// and throws otherwise.
void jsonMalformedTest(name, expect, codes) {
  // Helper method.
  void test(name, expect, action(sink)) {
    var tag = "Malform:$name-$expect";
    {  // Allowing malformed, expect [expect]
      var sink = new ChunkedConversionSink.withCallback((values) {
        var value = values[0];
        Expect.equals(expect, value, tag);
      });
      var decoderSink = JSON.decoder.startChunkedConversion(sink)
                                    .asUtf8Sink(true);
      try {
        action(decoderSink);
      } catch (e, s) {
        Expect.fail("Unexpected throw ($tag): $e\n$s");
      }
    }
    {  // Not allowing malformed, expect throw.
      var sink = new ChunkedConversionSink.withCallback((values) {
        Expect.unreachable(tag);
      });
      var decoderSink = JSON.decoder.startChunkedConversion(sink)
                                    .asUtf8Sink(false);
      Expect.throws(() { action(decoderSink); }, null, tag);
    }
  }

  // Test all two and three part slices.
  for (int i = 1; i < codes.length - 1; i++) {
    test("$name:$i", expect, (sink) {
      sink.add(codes.sublist(0, i));
      sink.add(codes.sublist(i));
      sink.close();
    });
    test("$name:$i-slice", expect, (sink) {
      sink.addSlice(codes, 0, i, false);
      sink.addSlice(codes, i, codes.length, true);
    });
    for (int j = i; j < codes.length - 1; j++) {
      test("$name:$i|$j", expect, (sink) {
        sink.add(codes.sublist(0, i));
        sink.add(codes.sublist(i, j));
        sink.add(codes.sublist(j));
        sink.close();
      });
    }
  }
}

// Test that `codeString.codeUnits` fails to parse as UTF-8 JSON,
// even with decoder not throwing on malformed encodings.
void jsonThrows(String name, String codeString) {
  testJsonThrows(tag, action) {
    // Not allowing malformed, expect throw.
    var sink = new ChunkedConversionSink.withCallback((values) {
      Expect.unreachable(tag);
    });
    var decoderSink = JSON.decoder.startChunkedConversion(sink)
                                  .asUtf8Sink(true);
    Expect.throws(() { action(decoderSink); }, null, tag);
  }

  var codes = codeString.codeUnits;
  for (int i = 1; i < codes.length - 1; i++) {
    testJsonThrows("$name:$i", (sink) {
      sink.add(codes.sublist(0, i));
      sink.add(codes.sublist(i));
      sink.close();
    });
    testJsonThrows("$name:$i-slice", (sink) {
      sink.addSlice(codes, 0, i, false);
      sink.addSlice(codes, i, codes.length, true);
    });
    for (int j = i; j < codes.length - 1; j++) {
      testJsonThrows("$name:$i|$j", (sink) {
        sink.add(codes.sublist(0, i));
        sink.add(codes.sublist(i, j));
        sink.add(codes.sublist(j));
        sink.close();
      });
    }
  }
}

// Malformed UTF-8 encodings.
void testMalformed() {
  // Overlong encodings.
  jsonMalformedTest("overlong-0-2", "@\uFFFD@",
                    [0x22, 0x40, 0xc0, 0x80, 0x40, 0x22]);
  jsonMalformedTest("overlong-0-3", "@\uFFFD@",
                    [0x22, 0x40, 0xe0, 0x80, 0x80, 0x40, 0x22]);
  jsonMalformedTest("overlong-0-4", "@\uFFFD@",
                    [0x22, 0x40, 0xf0, 0x80, 0x80, 0x80, 0x40, 0x22]);

  jsonMalformedTest("overlong-7f-2", "@\uFFFD@",
                    [0x22, 0x40, 0xc1, 0xbf, 0x40, 0x22]);
  jsonMalformedTest("overlong-7f-3", "@\uFFFD@",
                    [0x22, 0x40, 0xe0, 0x81, 0xbf, 0x40, 0x22]);
  jsonMalformedTest("overlong-7f-4", "@\uFFFD@",
                    [0x22, 0x40, 0xf0, 0x80, 0x81, 0xbf, 0x40, 0x22]);

  jsonMalformedTest("overlong-80-3", "@\uFFFD@",
                    [0x22, 0x40, 0xe0, 0x82, 0x80, 0x40, 0x22]);
  jsonMalformedTest("overlong-80-4", "@\uFFFD@",
                    [0x22, 0x40, 0xf0, 0x80, 0x82, 0x80, 0x40, 0x22]);

  jsonMalformedTest("overlong-7ff-3", "@\uFFFD@",
                    [0x22, 0x40, 0xe0, 0x9f, 0xbf, 0x40, 0x22]);
  jsonMalformedTest("overlong-7ff-4", "@\uFFFD@",
                    [0x22, 0x40, 0xf0, 0x80, 0x9f, 0xbf, 0x40, 0x22]);

  jsonMalformedTest("overlong-800-4", "@\uFFFD@",
                    [0x22, 0x40, 0xf0, 0x80, 0xa0, 0x80, 0x40, 0x22]);
  jsonMalformedTest("overlong-ffff-4", "@\uFFFD@",
                    [0x22, 0x40, 0xf0, 0x8f, 0xbf, 0xbf, 0x40, 0x22]);

  // Unterminated multibyte sequences.
  jsonMalformedTest("unterminated-2-normal", "@\uFFFD@",
                    [0x22, 0x40, 0xc0, 0x40, 0x22]);

  jsonMalformedTest("unterminated-3-normal", "@\uFFFD@",
                    [0x22, 0x40, 0xe0, 0x80, 0x40, 0x22]);

  jsonMalformedTest("unterminated-4-normal", "@\uFFFD@",
                    [0x22, 0x40, 0xf0, 0x80, 0x80, 0x40, 0x22]);

  jsonMalformedTest("unterminated-2-multi", "@\uFFFD\x80@",
                    [0x22, 0x40, 0xc0, 0xc2, 0x80, 0x40, 0x22]);

  jsonMalformedTest("unterminated-3-multi", "@\uFFFD\x80@",
                    [0x22, 0x40, 0xe0, 0x80, 0xc2, 0x80, 0x40, 0x22]);

  jsonMalformedTest("unterminated-4-multi", "@\uFFFD\x80@",
                    [0x22, 0x40, 0xf0, 0x80, 0x80, 0xc2, 0x80, 0x40, 0x22]);

  jsonMalformedTest("unterminated-2-escape", "@\uFFFD\n@",
                    [0x22, 0x40, 0xc0, 0x5c, 0x6e, 0x40, 0x22]);

  jsonMalformedTest("unterminated-3-escape", "@\uFFFD\n@",
                    [0x22, 0x40, 0xe0, 0x80, 0x5c, 0x6e, 0x40, 0x22]);

  jsonMalformedTest("unterminated-4-escape", "@\uFFFD\n@",
                    [0x22, 0x40, 0xf0, 0x80, 0x80, 0x5c, 0x6e, 0x40, 0x22]);

  jsonMalformedTest("unterminated-2-end", "@\uFFFD",
                    [0x22, 0x40, 0xc0, 0x22]);

  jsonMalformedTest("unterminated-3-end", "@\uFFFD",
                    [0x22, 0x40, 0xe0, 0x80, 0x22]);

  jsonMalformedTest("unterminated-4-end", "@\uFFFD",
                    [0x22, 0x40, 0xf0, 0x80, 0x80, 0x22]);

  // Unexpected continuation byte
  // - after a normal character.
  jsonMalformedTest("continuation-normal", "@\uFFFD@",
                    [0x22, 0x40, 0x80, 0x40, 0x22]);

  // - after a valid continuation byte.
  jsonMalformedTest("continuation-continuation-2", "@\x80\uFFFD@",
                    [0x22, 0x40, 0xc2, 0x80, 0x80, 0x40, 0x22]);
  jsonMalformedTest("continuation-continuation-3", "@\u0800\uFFFD@",
                    [0x22, 0x40, 0xe0, 0xa0, 0x80, 0x80, 0x40, 0x22]);
  jsonMalformedTest("continuation-continuation-4", "@\u{10000}\uFFFD@",
                    [0x22, 0x40, 0xf0, 0x90, 0x80, 0x80, 0x80, 0x40, 0x22]);

  // - after another invalid continuation byte
  jsonMalformedTest("continuation-twice", "@\uFFFD\uFFFD\uFFFD@",
                    [0x22, 0x40, 0x80, 0x80, 0x80, 0x40, 0x22]);
  // - at start.
  jsonMalformedTest("continuation-start", "\uFFFD@",
                    [0x22, 0x80, 0x40, 0x22]);

  // Unexpected leading byte where continuation byte expected.
  jsonMalformedTest("leading-2", "@\uFFFD\x80@",
                    [0x22, 0x40, 0xc0, 0xc2, 0x80, 0x40, 0x22]);
  jsonMalformedTest("leading-3-1", "@\uFFFD\x80@",
                    [0x22, 0x40, 0xe0, 0xc2, 0x80, 0x40, 0x22]);
  jsonMalformedTest("leading-3-2", "@\uFFFD\x80@",
                    [0x22, 0x40, 0xe0, 0x80, 0xc2, 0x80, 0x40, 0x22]);
  jsonMalformedTest("leading-4-1", "@\uFFFD\x80@",
                    [0x22, 0x40, 0xf0, 0xc2, 0x80, 0x40, 0x22]);
  jsonMalformedTest("leading-4-2", "@\uFFFD\x80@",
                    [0x22, 0x40, 0xf0, 0x80, 0xc2, 0x80, 0x40, 0x22]);
  jsonMalformedTest("leading-4-3", "@\uFFFD\x80@",
                    [0x22, 0x40, 0xf0, 0x80, 0x80, 0xc2, 0x80, 0x40, 0x22]);

  // Overlong encodings of ASCII outside of strings always fail.
  // Use Latin-1 strings as argument since most chars are correct,
  // pass string.codeUnits to decoder as UTF-8.
  jsonThrows("number-1", "\xc0\xab0.0e-0");  // '-' is 0x2b => \xc0\xab
  jsonThrows("number-2", "-\xc0\xb0.0e-0");  // '0' is 0x30 => \xc0\xb0
  jsonThrows("number-3", "-0\xc0\xae0e-0");  // '.' is 0x2e => \xc0\xae
  jsonThrows("number-4", "-0.\xc0\xb0e-0");
  jsonThrows("number-5", "-0.0\xc1\xa5-0");  // 'e' is 0x65 => \xc1\xa5
  jsonThrows("number-6", "-0.0e\xc0\xab0");
  jsonThrows("number-7", "-0.0e-\xc0\xb0");

  jsonThrows("true-1", "\xc1\xb4rue");  // 't' is 0x74
  jsonThrows("true-2", "t\xc1\xb2ue");  // 'r' is 0x72
  jsonThrows("true-3", "tr\xc1\xb5e");  // 'u' is 0x75
  jsonThrows("true-4", "tru\xc1\xa5");  // 'e' is 0x65

  jsonThrows("false-1", "\xc1\xa6alse");  // 'f' is 0x66
  jsonThrows("false-2", "f\xc1\xa1lse");  // 'a' is 0x61
  jsonThrows("false-3", "fa\xc1\xacse");  // 'l' is 0x6c
  jsonThrows("false-4", "fal\xc1\xb3e");  // 's' is 0x73
  jsonThrows("false-5", "fals\xc1\xa5");  // 'e' is 0x65

  jsonThrows("null-1", "\xc1\xaeull");  // 'n' is 0x6e
  jsonThrows("null-2", "n\xc1\xb5ll");  // 'u' is 0x75
  jsonThrows("null-3", "nu\xc1\xacl");  // 'l' is 0x6c
  jsonThrows("null-4", "nul\xc1\xac");  // 'l' is 0x6c

  jsonThrows("array-1", "\xc1\x9b0,0]");  // '[' is 0x5b
  jsonThrows("array-2", "[0,0\xc1\x9d");  // ']' is 0x5d
  jsonThrows("array-2", "[0\xc0\xac0]");  // ',' is 0x2c

  jsonThrows("object-1", '\xc1\xbb"x":0}');  // '{' is 0x7b
  jsonThrows("object-2", '{"x":0\xc1\xbd');  // '}' is 0x7d
  jsonThrows("object-2", '{"x\xc0\xba0}');  // ':' is 0x3a

  jsonThrows("string-1", '\xc0\xa2x"');  // '"' is 0x22
  jsonThrows("string-1", '"x\xc0\xa2');  // Unterminated string.

  jsonThrows("whitespace-1", "\xc0\xa01");  // ' ' is 0x20
}

void testUnicodeTests() {
  for (var pair in UNICODE_TESTS) {
    var bytes = pair[0];
    var string = pair[1];
    int step = 1;
    if (bytes.length > 100) step = bytes.length ~/ 13;
    for (int i = 1; i < bytes.length - 1; i += step) {
      jsonTest("$string:$i", string, (sink) {
        sink.add([0x22]);  // Double-quote.
        sink.add(bytes.sublist(0, i));
        sink.add(bytes.sublist(i));
        sink.add([0x22]);
        sink.close();
      });
      jsonTest("$string:$i-slice", string, (sink) {
        sink.addSlice([0x22], 0, 1, false);
        sink.addSlice(bytes, 0, i, false);
        sink.addSlice(bytes, i, bytes.length, false);
        sink.addSlice([0x22], 0, 1, true);
      });
      int skip = 1;
      if (bytes.length > 25) skip = bytes.length ~/ 17;
      for (int j = i; j < bytes.length - 1; j += skip) {
        jsonTest("$string:$i|$j", string, (sink) {
          sink.add([0x22]);
          sink.add(bytes.sublist(0, i));
          sink.add(bytes.sublist(i, j));
          sink.add(bytes.sublist(j));
          sink.add([0x22]);
          sink.close();
        });
      }
    }
  }
}
