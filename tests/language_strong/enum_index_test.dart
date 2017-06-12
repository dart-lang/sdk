// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-enum

// Test index access for enums.

library enum_index_test;

import 'package:expect/expect.dart';

enum Enum {
  A,
  B,
}

class Class {
  var index;
}

main() {
  test(null, new Class());
  test(0, Enum.A);
  test(1, Enum.B);
}

test(expected, object) {
  Expect.equals(expected, object.index);
}
