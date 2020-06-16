// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

library math_lib_prefix_test;

import "package:expect/expect.dart";
import 'dart:math' as foo;

main() {
  Expect.equals(2.0, foo.sqrt(4));
  Expect.equals(2.25, foo.pow(1.5, 2.0));

  int i = new foo.Random().nextInt(256);
  double d = new foo.Random().nextDouble();
  bool b = new foo.Random().nextBool();
}
