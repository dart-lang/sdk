// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that lazily-loaded fields are properly reset after hot restarts.

import 'package:expect/expect.dart';
import 'dart:_runtime' as dart;

double lazy = 3.14;

class Lazies {
  static String s = "default";
}

main() {
  Expect.equals(Lazies.s, "default");
  Lazies.s = "set";
  Expect.equals(Lazies.s, "set");
  Expect.equals(lazy, 3.14);
  lazy = 2.72;
  Expect.equals(lazy, 2.72);

  dart.hotRestart();

  Expect.equals(Lazies.s, "default");
  Lazies.s = "set";
  Expect.equals(Lazies.s, "set");
  Expect.equals(lazy, 3.14);
  lazy = 2.72;
  Expect.equals(lazy, 2.72);

  dart.hotRestart();
  dart.hotRestart();

  Expect.equals(Lazies.s, "default");
  Expect.equals(lazy, 3.14);
}
