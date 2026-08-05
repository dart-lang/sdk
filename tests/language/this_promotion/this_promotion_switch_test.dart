// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=this-promotion

import 'package:expect/static_type_helper.dart';

class A {
  void aOnly() {}
}

class ClassTest extends A {
  void testClass() {
    // 1. Switch statement
    switch (this) {
      case B():
        this.bOnly();
        bOnly();
        this.expectStaticType<Exactly<B>>();
    }

    // 2. Switch expression
    var _ = switch (this) {
      B() => <void>[this.expectStaticType<Exactly<B>>(), bOnly(), this.bOnly()],
      _ => null,
    };

    // 3. If-case statement
    if (this case B()) {
      this.bOnly();
      bOnly();
      this.expectStaticType<Exactly<B>>();
    }
  }
}

mixin M on A {
  void testMixin() {
    // 1. Switch statement
    switch (this) {
      case B():
        this.bOnly();
        bOnly();
        this.expectStaticType<Exactly<B>>();
    }

    // 2. Switch expression
    var _ = switch (this) {
      B() => <void>[this.expectStaticType<Exactly<B>>(), bOnly(), this.bOnly()],
      _ => null,
    };

    // 3. If-case statement
    if (this case B()) {
      this.bOnly();
      bOnly();
      this.expectStaticType<Exactly<B>>();
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
        this.bOnly();
        bOnly();
        this.expectStaticType<Exactly<B>>();
    }

    // 2. Switch expression
    var _ = switch (this) {
      B() => <void>[this.expectStaticType<Exactly<B>>(), bOnly(), this.bOnly()],
      _ => null,
    };

    // 3. If-case statement
    if (this case B()) {
      this.bOnly();
      bOnly();
      this.expectStaticType<Exactly<B>>();
    }
  }
}

void main() {
  var obj = B();
  obj.testClass();
  obj.testMixin();
  obj.testExtension();
}
