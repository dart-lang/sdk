// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.12

// Confirm that `this` does not get promoted when the feature isn't
// enabled. This test specifically covers switch statements, switch expressions,
// and the "if case" construct.

import 'package:expect/static_type_helper.dart';

class A {
  void aOnly() {}
}

class ClassTest extends A {
  void testClass() {
    // 1. Switch statement
    switch (this) {
      case B():
        this.expectStaticType<Exactly<ClassTest>>();
    }

    // 2. Switch expression
    var _ = switch (this) {
      B() => <void>[this.expectStaticType<Exactly<ClassTest>>()],
      _ => null,
    };

    // 3. If-case statement
    if (this case B()) {
      this.expectStaticType<Exactly<ClassTest>>();
    }
  }
}

mixin M on A {
  void testMixin() {
    // 1. Switch statement
    switch (this) {
      case B():
        this.expectStaticType<Exactly<M>>();
    }

    // 2. Switch expression
    var _ = switch (this) {
      B() => <void>[this.expectStaticType<Exactly<M>>()],
      _ => null,
    };

    // 3. If-case statement
    if (this case B()) {
      this.expectStaticType<Exactly<M>>();
    }
  }
}

class B extends ClassTest with M {
  void bOnly() {}
}

extension Ext on A {
  void testExtension() {
    // 1. Switch statement
    switch (this) {
      case B():
        this.expectStaticType<Exactly<A>>();
    }

    // 2. Switch expression
    var _ = switch (this) {
      B() => <void>[this.expectStaticType<Exactly<A>>()],
      _ => null,
    };

    // 3. If-case statement
    if (this case B()) {
      this.expectStaticType<Exactly<A>>();
    }
  }
}

void main() {
  var obj = B();
  obj.testClass();
  obj.testMixin();
  obj.testExtension();
}
