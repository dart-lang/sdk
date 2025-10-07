// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

// TODO(johnniwinther): Support testing of internal libraries.
import 'dart:_foreign_helper' show JS; // error

test() {
  String x = JS('int', '42'); // error
  var y = JS<String>('String', '"hello"');
  y = "world";
  y = 42; // error
}

main() {}
