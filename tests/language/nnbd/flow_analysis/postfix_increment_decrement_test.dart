// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/static_type_helper.dart';

// This test checks that `x++` and `x--` demote `x` to the type returned by the
// `+` or `-` operator defined on the previously-promoted type of `x`.
//
// It further verifies that when `x` is `int`, `x++` and `x--` do not demote to
// `num`, because of the special type inference rule that adding or subtracting
// two ints yields an int.

increment_int(num x) {
  if (x is int) {
    x++;
    x.expectStaticType<Exactly<int>>();
  }
}

decrement_int(num x) {
  if (x is int) {
    x--;
    x.expectStaticType<Exactly<int>>();
  }
}

increment_userDefinedType(B x) {
  if (x is C) {
    if (x is D) {
      x++;
      x.expectStaticType<Exactly<C>>();
    }
  }
}

decrement_userDefinedType(B x) {
  if (x is C) {
    if (x is D) {
      x++;
      x.expectStaticType<Exactly<C>>();
    }
  }
}

class B {}

class C extends B {}

class D extends C {
  C operator +(int i) => this;
  C operator -(int i) => this;
}

main() {
  increment_int(0);
  decrement_int(0);
  increment_userDefinedType(D());
  decrement_userDefinedType(D());
}
