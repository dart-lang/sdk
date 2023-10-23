// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion logic properly handles promotable fields declared
// in mixins.

// This test exercises both syntactic forms of creating mixin applications
// (`class C = B with M;` and `class C extends B with M {}`), since these are
// represented differently in the analyzer.

// This test exercises both the scenario in which the mixin declaration precedes
// the application, and the scenario in which it follows it. This ensures that
// the order in which the mixin declaration and application are analyzed does
// not influence the behavior.

// SharedOptions=--enable-experiment=inference-update-2

import '../static_type_helper.dart';

class C1 = Object with M;

class C2 extends Object with M {}

mixin M {
  final int? _nonLate = 0;
  late final int? _late = 0;
}

class C3 = Object with M;

class C4 extends Object with M {}

void test(C1 c1, C2 c2, C3 c3, C4 c4) {
  if (c1._nonLate != null) {
    c1._nonLate.expectStaticType<Exactly<int>>();
  }
  if (c1._late != null) {
    c1._late.expectStaticType<Exactly<int>>();
  }
  if (c2._nonLate != null) {
    c2._nonLate.expectStaticType<Exactly<int>>();
  }
  if (c2._late != null) {
    c2._late.expectStaticType<Exactly<int>>();
  }
  if (c3._nonLate != null) {
    c3._nonLate.expectStaticType<Exactly<int>>();
  }
  if (c3._late != null) {
    c3._late.expectStaticType<Exactly<int>>();
  }
  if (c4._nonLate != null) {
    c4._nonLate.expectStaticType<Exactly<int>>();
  }
  if (c4._late != null) {
    c4._late.expectStaticType<Exactly<int>>();
  }
}

main() {
  test(C1(), C2(), C3(), C4());
}
