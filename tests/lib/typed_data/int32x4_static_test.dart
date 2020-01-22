// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library int32x4_static_test;

import 'dart:typed_data';

main() {
  var str = "foo";
  new Int32x4(str, 2, 3, 4); //# 01: compile-time error

  var d = 0.5;
  new Int32x4(d, 2, 3, 4); //# 02: compile-time error
}
