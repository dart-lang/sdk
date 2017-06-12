// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:convert';

final TESTS = [
  [5, '5'],
  [-42, '-42'],
  [3.14, '3.14'],
  [true, 'true'],
  [false, 'false'],
  [null, 'null'],
  ['quote"or\'', '"quote\\"or\'"'],
  ['', '""'],
  [[], "[]"],
  [
    [3, -4.5, true, "hi", false],
    '[3,-4.5,true,"hi",false]'
  ],
  [
    [null],
    "[null]"
  ],
  [
    [
      [null]
    ],
    "[[null]]"
  ],
  [
    [
      [3]
    ],
    "[[3]]"
  ],
  [{}, "{}"],
  [
    {"x": 3, "y": 4.5, "z": "hi", "u": true, "v": false},
    '{"x":3,"y":4.5,"z":"hi","u":true,"v":false}'
  ],
  [
    {"x": null},
    '{"x":null}'
  ],
  [
    {"x": {}},
    '{"x":{}}'
  ],
  // Note that -0.0 won't be treated the same in JS. The Json spec seems to
  // allow it, though.
  // TODO(rnystrom): Changed to "0". See above comment.
  [
    {"hi there": 499, "'": -0.0},
    '{"hi there":499,"\'":0}'
  ],
  [r'\foo', r'"\\foo"'],
];

class MyStringConversionSink extends StringConversionSinkBase {
  var buffer = new StringBuffer();
  var callback;

  MyStringConversionSink(this.callback);

  addSlice(str, start, end, bool isLast) {
    buffer.write(str.substring(start, end));
    if (isLast) close();
  }

  close() {
    callback(buffer.toString());
  }
}

String encode(Object o) {
  var result;
  var encoder = new JsonEncoder();
  ChunkedConversionSink stringSink =
      new MyStringConversionSink((x) => result = x);
  var objectSink = new JsonEncoder().startChunkedConversion(stringSink);
  objectSink.add(o);
  objectSink.close();
  return result;
}

String encode2(Object o) {
  var result;
  var encoder = new JsonEncoder();
  ChunkedConversionSink stringSink =
      new StringConversionSink.withCallback((x) => result = x);
  var objectSink = encoder.startChunkedConversion(stringSink);
  objectSink.add(o);
  objectSink.close();
  return result;
}

main() {
  for (var test in TESTS) {
    var o = test[0];
    var expected = test[1];
    Expect.equals(expected, encode(o));
    Expect.equals(expected, encode2(o));
  }
}
