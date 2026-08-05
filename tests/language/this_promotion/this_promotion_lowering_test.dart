// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=this-promotion

// The CFE has several lowered representations for expressions involving
// explicit or implicit `this`. In this test we try to exercise as many of those
// lowered representations as we can think of.

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
      x.expectStaticType<Exactly<int>>();
      this.x.expectStaticType<Exactly<int>>();

      // 2. Simple member write (widen parameter to Object allows String)
      x = 'hello';
      this.x = 'hello';

      // 3. Method invocation (widen parameter to Object allows String)
      f('hello');
      this.f('hello');
      bOnly();
      this.bOnly();

      // 4. Compound assignment
      (x += 1).expectStaticType<Exactly<int>>();
      (this.x += 1).expectStaticType<Exactly<int>>();

      // 5. Pre/post increment/decrement
      (x++).expectStaticType<Exactly<int>>();
      (++x).expectStaticType<Exactly<int>>();
      (this.x++).expectStaticType<Exactly<int>>();
      (++this.x).expectStaticType<Exactly<int>>();

      // 6. Null-aware assignment (widen parameter to Object? allows String RHS)
      (z ??= 'hello').expectStaticType<Exactly<Object>>();
      (this.z ??= 'hello').expectStaticType<Exactly<Object>>();

      // 8. Index operators
      this[0].expectStaticType<Exactly<int>>();
      this[0] = 'hello';
      (this[0] += 1).expectStaticType<Exactly<int>>();
      (this[0]++).expectStaticType<Exactly<int>>();
      (++this[0]).expectStaticType<Exactly<int>>();
    }
  }
}

mixin M on A {
  void testMixin() {
    if (this is B) {
      // 1. Simple member read
      x.expectStaticType<Exactly<int>>();
      this.x.expectStaticType<Exactly<int>>();

      // 2. Simple member write (widen parameter to Object allows String)
      x = 'hello';
      this.x = 'hello';

      // 3. Method invocation (widen parameter to Object allows String)
      f('hello');
      this.f('hello');
      bOnly();
      this.bOnly();

      // 4. Compound assignment
      (x += 1).expectStaticType<Exactly<int>>();
      (this.x += 1).expectStaticType<Exactly<int>>();

      // 5. Pre/post increment/decrement
      (x++).expectStaticType<Exactly<int>>();
      (++x).expectStaticType<Exactly<int>>();
      (this.x++).expectStaticType<Exactly<int>>();
      (++this.x).expectStaticType<Exactly<int>>();

      // 6. Null-aware assignment (widen parameter to Object? allows String RHS)
      (z ??= 'hello').expectStaticType<Exactly<Object>>();
      (this.z ??= 'hello').expectStaticType<Exactly<Object>>();

      // 8. Index operators
      this[0].expectStaticType<Exactly<int>>();
      this[0] = 'hello';
      (this[0] += 1).expectStaticType<Exactly<int>>();
      (this[0]++).expectStaticType<Exactly<int>>();
      (++this[0]).expectStaticType<Exactly<int>>();
    }
  }
}

extension Ext on A {
  void testExtension() {
    if (this is B) {
      // 1. Simple member read
      x.expectStaticType<Exactly<int>>();
      this.x.expectStaticType<Exactly<int>>();

      // 2. Simple member write (widen parameter to Object allows String)
      x = 'hello';
      this.x = 'hello';

      // 3. Method invocation (widen parameter to Object allows String)
      f('hello');
      this.f('hello');
      bOnly();
      this.bOnly();

      // 4. Compound assignment
      (x += 1).expectStaticType<Exactly<int>>();
      (this.x += 1).expectStaticType<Exactly<int>>();

      // 5. Pre/post increment/decrement
      (x++).expectStaticType<Exactly<int>>();
      (++x).expectStaticType<Exactly<int>>();
      (this.x++).expectStaticType<Exactly<int>>();
      (++this.x).expectStaticType<Exactly<int>>();

      // 6. Null-aware assignment (widen parameter to Object? allows String RHS)
      (z ??= 'hello').expectStaticType<Exactly<Object>>();
      (this.z ??= 'hello').expectStaticType<Exactly<Object>>();

      // 8. Index operators
      this[0].expectStaticType<Exactly<int>>();
      this[0] = 'hello';
      (this[0] += 1).expectStaticType<Exactly<int>>();
      (this[0]++).expectStaticType<Exactly<int>>();
      (++this[0]).expectStaticType<Exactly<int>>();
    }
  }
}

extension ExtNullable on A? {
  void testExtensionNullable() {
    if (this is B?) {
      // 7. Null shorting (tested on nullable `this` promoted to nullable `B?`)
      (this?.x).expectStaticType<Exactly<int?>>();
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
