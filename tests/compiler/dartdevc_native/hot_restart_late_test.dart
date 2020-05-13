// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that late fields are properly reset after hot restarts.

// Requirements=nnbd

import 'package:expect/expect.dart';
import 'dart:_runtime' as dart;

class Lates {
  late String s;
}

main() {
  var l = Lates();

  Expect.throws(() => l.s);
  l.s = "set";
  Expect.equals(l.s, "set");

  dart.hotRestart();

  Expect.throws(() => l.s);
  l.s = "set";
  Expect.equals(l.s, "set");

  dart.hotRestart();
  dart.hotRestart();

  Expect.throws(() => l.s);
}
