// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html_common';
import 'package:expect/expect.dart';
import 'package:expect/minitest.dart';

var obj = {
  'val1': 'hello',
  'val2': 'there',
  'val3': {
    'sub1': 'general kenobi',
    'sub2': 'you are',
    'sub3': 'a bold one',
    'sub4': {
      'nilval': null,
      'boolval': false,
    }
  },
  'val4': [
    'execute',
    'order',
    '66',
    {'number': 33}
  ]
};

main() {
  test('dart to native -> native to dart', () {
    var toNative = convertDartToNative_Dictionary(obj);
    var toDart = convertNativeToDart_Dictionary(toNative);

    Expect.deepEquals(obj, toDart);
  });
}
