// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:convert';
import 'unicode_tests.dart';

List<int> encode(String str) => new Utf8Encoder().convert(str);
List<int> encode2(String str) => UTF8.encode(str);

main() {
  for (var test in UNICODE_TESTS) {
    List<int> bytes = test[0];
    String string = test[1];
    Expect.listEquals(bytes, encode(string));
    Expect.listEquals(bytes, encode2(string));
  }
}
