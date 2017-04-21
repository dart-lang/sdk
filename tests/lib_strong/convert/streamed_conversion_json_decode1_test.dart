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

bool isJsonEqual(o1, o2) {
  if (o1 == o2) return true;
  if (o1 is List && o2 is List) {
    if (o1.length != o2.length) return false;
    for (int i = 0; i < o1.length; i++) {
      if (!isJsonEqual(o1[i], o2[i])) return false;
    }
    return true;
  }
  if (o1 is Map && o2 is Map) {
    if (o1.length != o2.length) return false;
    for (var key in o1.keys) {
      Expect.isTrue(key is String);
      if (!o2.containsKey(key)) return false;
      if (!isJsonEqual(o1[key], o2[key])) return false;
    }
    return true;
  }
  return false;
}

Stream<Object> createStream(List<String> chunks) {
  var decoder = new JsonDecoder(null);
  var controller;
  controller = new StreamController(onListen: () {
    chunks.forEach(controller.add);
    controller.close();
  });
  return controller.stream.transform(decoder);
}

Stream<Object> decode(String str) {
  return createStream([str]);
}

Stream<Object> decode2(String str) {
  return createStream(str.split(""));
}

void checkIsJsonEqual(expected, stream) {
  asyncStart();
  stream.single.then((o) {
    Expect.isTrue(isJsonEqual(expected, o));
    asyncEnd();
  });
}

void main() {
  var tests = TESTS.expand((test) {
    var object = test[0];
    var string = test[1];
    var longString = "                                                        "
        "                                                        "
        "$string"
        "                                                        "
        "                                                        ";
    return [
      test,
      [object, longString]
    ];
  });
  for (var test in TESTS) {
    var o = test[0];
    var string = test[1];
    checkIsJsonEqual(o, decode(string));
    checkIsJsonEqual(o, decode2(string));
  }
}
