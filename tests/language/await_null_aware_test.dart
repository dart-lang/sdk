// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue dartbug.com/24392

import 'package:expect/expect.dart';
import 'dart:async';

Future<int> f() async {
  // Unreachable.
  Expect.isTrue(false);
}

main() async {
  int x = 1;
  x ??= await f();
  Expect.equals(1, x);

  int y = 1;
  y = y ?? await f();
  Expect.equals(1, y);
}
