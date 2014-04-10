// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library json_pretty_test;

import 'dart:convert';

import 'package:matcher/matcher.dart';

void _testIndentWithNullChar() {
  var encoder = const JsonEncoder.withIndent('\x00');
  var encoded = encoder.convert([[],[[]]]);
  expect(encoded, "[\n\x00[],\n\x00[\n\x00\x00[]\n\x00]\n]");
}

void main() {
  _testIndentWithNullChar();

  _expect(null, 'null');

  _expect([[],[[]]], '''
[
  [],
  [
    []
  ]
]''');

  _expect([1, 2, 3, 4], '''
[
  1,
  2,
  3,
  4
]''');

  _expect([true, null, 'hello', 42.42],
      '''
[
  true,
  null,
  "hello",
  42.42
]''');

  _expect({"hello": [], "goodbye": {} } ,
'''{
  "hello": [],
  "goodbye": {}
}''');

  _expect(["test", 1, 2, 33234.324, true, false, null, {
      "test1": "test2",
      "test3": "test4",
      "grace": 5,
      "shanna": [0, 1, 2]
    }, {
      "lib": "app.dart",
      "src": ["foo.dart", "bar.dart"]
    }],
        '''[
  "test",
  1,
  2,
  33234.324,
  true,
  false,
  null,
  {
    "test1": "test2",
    "test3": "test4",
    "grace": 5,
    "shanna": [
      0,
      1,
      2
    ]
  },
  {
    "lib": "app.dart",
    "src": [
      "foo.dart",
      "bar.dart"
    ]
  }
]''');
}

void _expect(Object object, String expected) {
  var encoder = const JsonEncoder.withIndent('  ');
  var prettyOutput = encoder.convert(object);

  expect(prettyOutput, expected);

  encoder = const JsonEncoder.withIndent('');

  var flatOutput = encoder.convert(object);

  var flatExpected = const LineSplitter().convert(expected)
      .map((line) => line.trimLeft())
      .join('\n');

  expect(flatOutput, flatExpected);

  var compactOutput = JSON.encode(object);

  encoder = const JsonEncoder.withIndent(null);
  expect(encoder.convert(object), compactOutput);

  var prettyDecoded = JSON.decode(prettyOutput);

  expect(JSON.encode(prettyDecoded), compactOutput);
}
