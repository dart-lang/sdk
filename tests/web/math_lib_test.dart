// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library math_lib_test;

import "package:expect/expect.dart";
import 'dart:math';

main() {
  Expect.equals(2.0, sqrt(4));
  Expect.equals(2.25, pow(1.5, 2.0));

  int i = new Random().nextInt(256);
  double d = new Random().nextDouble();
  bool b = new Random().nextBool();
}
