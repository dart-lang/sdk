// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that late fields are properly reset after hot restarts.

// Requirements=nnbd

import 'package:expect/expect.dart';
import 'dart:_runtime' as dart;

late double l;

class Lates {
  static late String s;
}

main() {
  Expect.throws(() => Lates.s);
  Expect.throws(() => l);
  Lates.s = "set";
  l = 1.62;
  Expect.equals(Lates.s, "set");
  Expect.equals(l, 1.62);

  dart.hotRestart();

  Expect.throws(() => Lates.s);
  Expect.throws(() => l);
  Lates.s = "set";
  Expect.equals(Lates.s, "set");
  l = 1.62;
  Expect.equals(l, 1.62);

  dart.hotRestart();
  dart.hotRestart();

  Expect.throws(() => Lates.s);
  Expect.throws(() => l);
}
