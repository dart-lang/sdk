// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.12

import 'package:expect/static_type_helper.dart';

class A {
  num get x => 1;
  set x(num value) {}

  num? get z => 1;
  set z(num? value) {}

  void f(num val) {}

  num operator [](int index) => 1;
  void operator []=(int index, num value) {}
}

class B extends ClassTest with M {
  @override
  int get x => 2;
  @override
  set x(Object value) {}

  @override
  int? get z => 2;
  @override
  set z(Object? value) {}

  @override
  void f(Object val) {}

  @override
  int operator [](int index) => 2;
  @override
  void operator []=(int index, Object value) {}

  void bOnly() {}
}

class ClassTest extends A {
  void testClass() {
    if (this is B) {
      // 1. Simple member read
      x.expectStaticType<Exactly<num>>();
      this.x.expectStaticType<Exactly<num>>();

      // 2. Simple member write (without promotion, expects num)
      x = 1.5;
      this.x = 1.5;

      // 3. Method invocation (without promotion, expects num)
      f(1.5);
      this.f(1.5);

      // 4. Compound assignment
      (x += 1).expectStaticType<Exactly<num>>();
      (this.x += 1).expectStaticType<Exactly<num>>();

      // 5. Pre/post increment/decrement
      (x++).expectStaticType<Exactly<num>>();
      (++x).expectStaticType<Exactly<num>>();
      (this.x++).expectStaticType<Exactly<num>>();
      (++this.x).expectStaticType<Exactly<num>>();

      // 6. Null-aware assignment (without promotion, expects num?)
      (z ??= 1).expectStaticType<Exactly<num>>();
      (this.z ??= 1).expectStaticType<Exactly<num>>();

      // 8. Index operators
      this[0].expectStaticType<Exactly<num>>();
      this[0] = 1.5;
      (this[0] += 1).expectStaticType<Exactly<num>>();
      (this[0]++).expectStaticType<Exactly<num>>();
      (++this[0]).expectStaticType<Exactly<num>>();
    }
  }
}

mixin M on A {
  void testMixin() {
    if (this is B) {
      // 1. Simple member read
      x.expectStaticType<Exactly<num>>();
      this.x.expectStaticType<Exactly<num>>();

      // 2. Simple member write (without promotion, expects num)
      x = 1.5;
      this.x = 1.5;

      // 3. Method invocation (without promotion, expects num)
      f(1.5);
      this.f(1.5);

      // 4. Compound assignment
      (x += 1).expectStaticType<Exactly<num>>();
      (this.x += 1).expectStaticType<Exactly<num>>();

      // 5. Pre/post increment/decrement
      (x++).expectStaticType<Exactly<num>>();
      (++x).expectStaticType<Exactly<num>>();
      (this.x++).expectStaticType<Exactly<num>>();
      (++this.x).expectStaticType<Exactly<num>>();

      // 6. Null-aware assignment (without promotion, expects num?)
      (z ??= 1).expectStaticType<Exactly<num>>();
      (this.z ??= 1).expectStaticType<Exactly<num>>();

      // 8. Index operators
      this[0].expectStaticType<Exactly<num>>();
      this[0] = 1.5;
      (this[0] += 1).expectStaticType<Exactly<num>>();
      (this[0]++).expectStaticType<Exactly<num>>();
      (++this[0]).expectStaticType<Exactly<num>>();
    }
  }
}

extension Ext on A {
  void testExtension() {
    if (this is B) {
      // 1. Simple member read
      x.expectStaticType<Exactly<num>>();
      this.x.expectStaticType<Exactly<num>>();

      // 2. Simple member write (without promotion, expects num)
      x = 1.5;
      this.x = 1.5;

      // 3. Method invocation (without promotion, expects num)
      f(1.5);
      this.f(1.5);

      // 4. Compound assignment
      (x += 1).expectStaticType<Exactly<num>>();
      (this.x += 1).expectStaticType<Exactly<num>>();

      // 5. Pre/post increment/decrement
      (x++).expectStaticType<Exactly<num>>();
      (++x).expectStaticType<Exactly<num>>();
      (this.x++).expectStaticType<Exactly<num>>();
      (++this.x).expectStaticType<Exactly<num>>();

      // 6. Null-aware assignment (without promotion, expects num?)
      (z ??= 1).expectStaticType<Exactly<num>>();
      (this.z ??= 1).expectStaticType<Exactly<num>>();

      // 8. Index operators
      this[0].expectStaticType<Exactly<num>>();
      this[0] = 1.5;
      (this[0] += 1).expectStaticType<Exactly<num>>();
      (this[0]++).expectStaticType<Exactly<num>>();
      (++this[0]).expectStaticType<Exactly<num>>();
    }
  }
}

extension ExtNullable on A? {
  void testExtensionNullable() {
    if (this is B?) {
      // 7. Null shorting (without promotion remains `A?`)
      (this?.x).expectStaticType<Exactly<num?>>();
    }
  }
}

void main() {
  var obj = B();
  obj.testMixin();
  obj.testClass();
  obj.testExtension();
  obj.testExtensionNullable();
}
