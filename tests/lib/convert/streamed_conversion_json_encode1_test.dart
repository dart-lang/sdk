// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:convert';
import "package:async_helper/async_helper.dart";

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
  [
    {"hi there": 499, "'": -0.0},
    '{"hi there":499,"\'":-0.0}'
  ],
  [r'\foo', r'"\\foo"'],
];

Stream<String> encode(Object o) {
  var encoder = new JsonEncoder();
  StreamController controller;
  controller = new StreamController(onListen: () {
    controller.add(o);
    controller.close();
  });
  return controller.stream.transform(encoder);
}

void testNoPause(String expected, Object o) {
  asyncStart();
  Stream stream = encode(o);
  stream.toList().then((list) {
    StringBuffer buffer = new StringBuffer();
    buffer.writeAll(list);
    Expect.stringEquals(expected, buffer.toString());
    asyncEnd();
  });
}

void testWithPause(String expected, Object o) {
  asyncStart();
  Stream stream = encode(o);
  StringBuffer buffer = new StringBuffer();
  var sub;
  sub = stream.listen((x) {
    buffer.write(x);
    sub.pause(new Future.delayed(Duration.ZERO));
  }, onDone: () {
    Expect.stringEquals(expected, buffer.toString());
    asyncEnd();
  });
}

void main() {
  for (var test in TESTS) {
    var o = test[0];
    var expected = test[1];
    testNoPause(expected, o);
    testWithPause(expected, o);
  }
}
