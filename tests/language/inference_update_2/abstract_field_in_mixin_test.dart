// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion logic properly handles promotable abstract fields
// declared in mixins.

// In this test, there is no concrete implementation of the field in
// question. As such, it doesn't really reflect the way an abstract private
// field would be used in real-world code, but it's useful for making sure that
// an unimplemented abstract private field doesn't cause the analyzer or front
// end to misbehave. For another test in which there *is* a concrete
// implementation of the field, see
// `abstract_field_in_mixin_implemented_test.dart`.

// This test exercises both syntactic forms of creating mixin applications
// (`class C = B with M;` and `class C extends B with M {}`), since these are
// represented differently in the analyzer.

// This test exercises both the scenario in which the mixin declaration precedes
// the application, and the scenario in which it follows it. This ensures that
// the order in which the mixin declaration and application are analyzed does
// not influence the behavior.

import 'package:expect/static_type_helper.dart';

abstract class C1 = Object with M;

abstract class C2 extends Object with M {}

mixin M {
  abstract final int? _field;
}

abstract class C3 = Object with M;

abstract class C4 extends Object with M {}

void test(C1 c1, C2 c2, C3 c3, C4 c4) {
  if (c1._field != null) {
    c1._field.expectStaticType<Exactly<int>>();
  }
  if (c2._field != null) {
    c2._field.expectStaticType<Exactly<int>>();
  }
  if (c3._field != null) {
    c3._field.expectStaticType<Exactly<int>>();
  }
  if (c4._field != null) {
    c4._field.expectStaticType<Exactly<int>>();
  }
}

main() {}
