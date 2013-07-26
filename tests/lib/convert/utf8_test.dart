// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:convert';
import 'unicode_tests.dart';

String decode(List<int> bytes) => new Utf8Decoder().convert(bytes);

main() {
  for (var test in UNICODE_TESTS) {
    List<int> bytes = test[0];
    String expected = test[1];
    Expect.stringEquals(expected, decode(bytes));
  }
}
