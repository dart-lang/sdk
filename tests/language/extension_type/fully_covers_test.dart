// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that extension type erasure is used when computing whether
// a pattern fully covers the matched value type. This is necessary to avoid a
// "catch-22" situation in which flow analysis and the exhaustiveness checker
// disagree about the exhaustiveness of a switch statement. For details see
// https://github.com/dart-lang/language/issues/3534#issuecomment-1885839268.

import 'package:expect/static_type_helper.dart';

extension type E(int i) {}

// Helper method used to verify that a local variable has been definitely
// assigned.
void checkAssigned(Object? o) {}

testIfCase(E e, int i) {
  int? j = 0; // promotes `j` to `int`
  j.expectStaticType<Exactly<int>>();

  if (e case int _) {
    // reachable
  } else {
    // unreachable
    j = null; // demotes `j`
    j.expectStaticType<Exactly<int?>>();
  }
  // `j` is still promoted because the demotion is in an unreachable code path.
  j.expectStaticType<Exactly<int>>();

  if (i case E _) {
    // reachable
  } else {
    // unreachable
    j = null; // demotes `j`
    j.expectStaticType<Exactly<int?>>();
  }
  // `j` is still promoted because the demotion is in an unreachable code path.
  j.expectStaticType<Exactly<int>>();
}

testSwitchStatement(E e, int i) {
  {
    int j;
    switch (e) {
      case int _:
        j = 0;
    }
    // `int` fully covers `E`, so `j` has been definitely assigned now.
    checkAssigned(j);
  }

  {
    int j;
    switch (i) {
      case E _:
        j = 0;
    }
    // `int` fully covers `E`, so `j` has been definitely assigned now.
    checkAssigned(j);
  }
}

main() {
  testIfCase(E(0), 0);
  testSwitchStatement(E(0), 0);
}
