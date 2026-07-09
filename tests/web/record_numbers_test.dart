// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests record numeric subtyping rules with web semantics.
// Regression test for https://github.com/dart-lang/sdk/issues/52480

import "package:expect/expect.dart";

main() {
  Expect.notSubtype<(int, int), (double, double)>();
  Expect.notSubtype<(int, double), (double, double)>();
  Expect.notSubtype<(double, double), (int, int)>();
  Expect.notSubtype<(int, double), (int, int)>();

  Object mixedTuple = (0, 0.1);
  (double, double) doubleTuple = (0.0, 0.1);
  Object someTuple = doubleTuple;

  Expect.type<(double, double)>(mixedTuple);
  Expect.type<(int, double)>(mixedTuple);
  Expect.type<(double, double)>(someTuple);
  Expect.type<(int, double)>(someTuple);

  dynamic dynamicIntTuple = (4, 4);
  dynamic dynamicDoubleTuple = doubleTuple;

  Expect.type<(int, int)>(dynamicIntTuple);
  Expect.type<(int, double)>(dynamicIntTuple);
  Expect.type<(double, int)>(dynamicIntTuple);
  Expect.type<(double, double)>(dynamicIntTuple);
  Expect.notType<(int, int)>(dynamicDoubleTuple);
  Expect.type<(int, double)>(dynamicDoubleTuple);
  Expect.notType<(double, int)>(dynamicDoubleTuple);
  Expect.type<(double, double)>(dynamicDoubleTuple);
}
