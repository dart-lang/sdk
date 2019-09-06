// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--deterministic --enable-inlining-annotations

// Issue #37633 found with fuzzing: internal compiler crash (parallel move).

import 'dart:math';

import "package:expect/expect.dart";

const String NeverInline = 'NeverInline';

double foo0() {
  return acos(0.9474715118880382);
}

@NeverInline
double foo() {
  return atan2(foo0(), foo0());
}

main() {
  double x = foo();
  Expect.approxEquals(x, 0.7853981633974483);
}
