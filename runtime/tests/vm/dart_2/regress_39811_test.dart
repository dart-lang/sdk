// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--use-slow-path

import 'dart:math';

import 'package:expect/expect.dart';

main() {
  bool gotException = false;
  try {
    foo();
  } on RangeError catch (e, s) {
    gotException = true;
  }
  Expect.isTrue(gotException);
}

@pragma('vm:never-inline')
foo() {
  for (dynamic _ in [1, 2, 3]) {
    [(log2e as double).toStringAsFixed(37)];
  }
}
