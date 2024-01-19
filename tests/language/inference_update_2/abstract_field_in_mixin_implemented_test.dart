// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that field promotion logic properly handles promotable abstract fields
// declared in mixins.

// In this test, there are concrete implementations of the field in
// question. For another test in which there is *no* concrete implementation of
// the field, see `abstract_field_in_mixin_test.dart`.

// This test exercises both syntactic forms of creating mixin applications
// (`class C = B with M;` and `class C extends B with M {}`), since these are
// represented differently in the analyzer.

// This test exercises both the scenario in which the mixin declaration precedes
// the application, and the scenario in which it follows it. This ensures that
// the order in which the mixin declaration and application are analyzed does
// not influence the behavior.

// SharedOptions=--enable-experiment=inference-update-2

import '../static_type_helper.dart';

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

class ConcreteC1 extends C1 {
  final int? _field;
  ConcreteC1(this._field);
}

class ConcreteC2 extends C2 {
  final int? _field;
  ConcreteC2(this._field);
}

class ConcreteC3 extends C3 {
  final int? _field;
  ConcreteC3(this._field);
}

class ConcreteC4 extends C4 {
  final int? _field;
  ConcreteC4(this._field);
}

main() {
  test(ConcreteC1(0), ConcreteC2(0), ConcreteC3(0), ConcreteC4(0));
}
