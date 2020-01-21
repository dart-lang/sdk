// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:convert';

String decode(List<int> bytes) {
  StringBuffer buffer = new StringBuffer();
  var stringSink = new StringConversionSink.fromStringSink(buffer);
  var byteSink = new Utf8Decoder().startChunkedConversion(stringSink);
  bytes.forEach((byte) {
    byteSink.add([byte]);
  });
  byteSink.close();
  return buffer.toString();
}

String decodeAllowMalformed(List<int> bytes) {
  StringBuffer buffer = new StringBuffer();
  var stringSink = new StringConversionSink.fromStringSink(buffer);
  var decoder = new Utf8Decoder(allowMalformed: true);
  var byteSink = decoder.startChunkedConversion(stringSink);
  bytes.forEach((byte) {
    byteSink.add([byte]);
  });
  byteSink.close();
  return buffer.toString();
}

final TESTS = [
  // Unfinished UTF-8 sequences.
  [0xc3],
  [0xE2, 0x82],
  [0xF0, 0xA4, 0xAD],
  // Overlong encoding of euro-sign.
  [0xF0, 0x82, 0x82, 0xAC],
  // Other overlong/unfinished sequences.
  [0xC0],
  [0xC1],
  [0xF5],
  [0xF6],
  [0xF7],
  [0xF8],
  [0xF9],
  [0xFA],
  [0xFB],
  [0xFC],
  [0xFD],
  [0xFE],
  [0xFF],
  [0xC0, 0x80],
  [0xC1, 0x80],
  // Outside valid range.
  [0xF4, 0xBF, 0xBF, 0xBF]
];

final TESTS2 = [
  // Test that 0xC0|1, 0x80 does not eat the next character.
  [
    [0xC0, 0x80, 0x61],
    "Xa"
  ],
  [
    [0xC1, 0x80, 0x61],
    "Xa"
  ],
  // 0xF5 .. 0xFF never appear in valid UTF-8 sequences.
  [
    [0xF5, 0x80],
    "XX"
  ],
  [
    [0xF6, 0x80],
    "XX"
  ],
  [
    [0xF7, 0x80],
    "XX"
  ],
  [
    [0xF8, 0x80],
    "XX"
  ],
  [
    [0xF9, 0x80],
    "XX"
  ],
  [
    [0xFA, 0x80],
    "XX"
  ],
  [
    [0xFB, 0x80],
    "XX"
  ],
  [
    [0xFC, 0x80],
    "XX"
  ],
  [
    [0xFD, 0x80],
    "XX"
  ],
  [
    [0xFE, 0x80],
    "XX"
  ],
  [
    [0xFF, 0x80],
    "XX"
  ],
  [
    [0xF5, 0x80, 0x61],
    "XXa"
  ],
  [
    [0xF6, 0x80, 0x61],
    "XXa"
  ],
  [
    [0xF7, 0x80, 0x61],
    "XXa"
  ],
  [
    [0xF8, 0x80, 0x61],
    "XXa"
  ],
  [
    [0xF9, 0x80, 0x61],
    "XXa"
  ],
  [
    [0xFA, 0x80, 0x61],
    "XXa"
  ],
  [
    [0xFB, 0x80, 0x61],
    "XXa"
  ],
  [
    [0xFC, 0x80, 0x61],
    "XXa"
  ],
  [
    [0xFD, 0x80, 0x61],
    "XXa"
  ],
  [
    [0xFE, 0x80, 0x61],
    "XXa"
  ],
  [
    [0xFF, 0x80, 0x61],
    "XXa"
  ],
  // Characters outside the valid range.
  [
    [0xF5, 0x80, 0x80, 0x61],
    "XXXa"
  ],
  [
    [0xF6, 0x80, 0x80, 0x61],
    "XXXa"
  ],
  [
    [0xF7, 0x80, 0x80, 0x61],
    "XXXa"
  ],
  [
    [0xF8, 0x80, 0x80, 0x61],
    "XXXa"
  ],
  [
    [0xF9, 0x80, 0x80, 0x61],
    "XXXa"
  ],
  [
    [0xFA, 0x80, 0x80, 0x61],
    "XXXa"
  ],
  [
    [0xFB, 0x80, 0x80, 0x61],
    "XXXa"
  ],
  [
    [0xFC, 0x80, 0x80, 0x61],
    "XXXa"
  ],
  [
    [0xFD, 0x80, 0x80, 0x61],
    "XXXa"
  ],
  [
    [0xFE, 0x80, 0x80, 0x61],
    "XXXa"
  ],
  [
    [0xFF, 0x80, 0x80, 0x61],
    "XXXa"
  ]
];

main() {
  var allTests = TESTS.expand((test) {
    // Pairs of test and expected string output when malformed strings are
    // allowed. Replacement character: U+FFFD
    return [
      [test, "\u{FFFD}"],
      [
        new List<int>.from([0x61])..addAll(test),
        "a\u{FFFD}"
      ],
      [
        new List<int>.from([0x61])
          ..addAll(test)
          ..add(0x61),
        "a\u{FFFD}a"
      ],
      [new List<int>.from(test)..add(0x61), "\u{FFFD}a"],
      [new List<int>.from(test)..addAll(test), "\u{FFFD}\u{FFFD}"],
      [
        new List<int>.from(test)
          ..add(0x61)
          ..addAll(test),
        "\u{FFFD}a\u{FFFD}"
      ],
      [
        new List<int>.from([0xc3, 0xa5])..addAll(test),
        "å\u{FFFD}"
      ],
      [
        new List<int>.from([0xc3, 0xa5])..addAll(test)..addAll([0xc3, 0xa5]),
        "å\u{FFFD}å"
      ],
      [
        new List<int>.from(test)..addAll([0xc3, 0xa5]),
        "\u{FFFD}å"
      ],
      [
        new List<int>.from(test)..addAll([0xc3, 0xa5])..addAll(test),
        "\u{FFFD}å\u{FFFD}"
      ]
    ];
  });

  var allTests2 = TESTS2.map((test) {
    // Pairs of test and expected string output when malformed strings are
    // allowed. Replacement character: U+FFFD
    String expected = (test[1] as String).replaceAll("X", "\u{FFFD}");
    return [test[0], expected];
  });

  for (var test in []..addAll(allTests)..addAll(allTests2)) {
    List<int> bytes = test[0];
    Expect.throwsFormatException(() => decode(bytes));

    String expected = test[1];
    Expect.equals(expected, decodeAllowMalformed(bytes));
  }
}
