// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=this-promotion

// This test exercises some subtle corner cases of how `this` promotion
// interacts with lexical name lookup.
//
// See in particular the "Lexical Lookup" chapter of the spec, which says that
// when looking up a name `n` (basename `id`) at location `l`:
//
//   Let `S` be the innermost lexical scope containing `l` which has a
//   declaration with basename `id`. In the case where `S` has a declaration
//   named `id` as well as a declaration named `id=`, let `D` be the declaration
//   named `n`. In the situation where `S` has exactly one declaration with
//   basename `id`, let `D` be that declaration.
//   ...
//   - Consider the case where `D` is an instance member declaration in a class
//     or mixin `A`. The lexical lookup then yields nothing. _In this case it is
//     guaranteed that `l` has access to `this`._
//
// This means that an identifier `x` occurring in a class that contains an
// instance declaration named `x` will be treated as `this.x`, so `this`
// promotion should apply. Conversely, an identifier `x` occurring in an
// _extension_ that contains an instance declaration named `x` will _not_ be
// treated as `this.x`, so `this` promotion should not apply.

import 'package:expect/static_type_helper.dart';

class A {
  num get x => 1;
  set x(num value) {}

  num? get z => 1;
  set z(num? value) {}

  void f(num val) {}

  num operator [](int index) => 1;
  void operator []=(int index, num value) {}

  void testClass() {
    if (this is B) {
      // 1. Simple member read
      x.expectStaticType<Exactly<int>>();
      this.x.expectStaticType<Exactly<int>>();

      // 2. Simple member write (widen parameter to Object allows String)
      x = contextType('hello')..expectStaticType<Exactly<Object>>;
      this.x = contextType('hello')..expectStaticType<Exactly<Object>>;

      // 3. Method invocation (widen parameter to Object allows String)
      f(contextType('hello')..expectStaticType<Exactly<Object>>);
      this.f(contextType('hello')..expectStaticType<Exactly<Object>>);
      bOnly();
      this.bOnly();

      // 4. Compound assignment
      (x += contextType(
        1,
      )..expectStaticType<Exactly<num>>).expectStaticType<Exactly<num>>();
      (x += 1).expectStaticType<Exactly<int>>();
      (this.x += contextType(
        1,
      )..expectStaticType<Exactly<num>>).expectStaticType<Exactly<num>>();
      (this.x += 1).expectStaticType<Exactly<int>>();

      // 5. Pre/post increment/decrement
      (x++).expectStaticType<Exactly<int>>();
      (++x).expectStaticType<Exactly<int>>();
      (this.x++).expectStaticType<Exactly<int>>();
      (++this.x).expectStaticType<Exactly<int>>();

      // 6. Null-aware assignment (widen parameter to Object?)
      (z ??= contextType(1)..expectStaticType<Exactly<Object?>>)
          .expectStaticType<Exactly<Object?>>();
      (z ??= 1).expectStaticType<Exactly<int>>();
      (this.z ??= contextType(1)..expectStaticType<Exactly<Object?>>)
          .expectStaticType<Exactly<Object?>>();
      (this.z ??= 1).expectStaticType<Exactly<int>>();

      // 7. Index operators
      this[0].expectStaticType<Exactly<int>>();
      this[0] = contextType('hello')..expectStaticType<Exactly<Object>>;
      (this[0] += contextType(
        1,
      )..expectStaticType<Exactly<num>>).expectStaticType<Exactly<num>>();
      (this[0] += 1).expectStaticType<Exactly<int>>();
      (this[0]++).expectStaticType<Exactly<int>>();
      (++this[0]).expectStaticType<Exactly<int>>();
    }
  }
}

class B extends A {
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

extension Ext on A {
  num get x => 1;
  set x(num value) {}

  num? get z => 1;
  set z(num? value) {}

  void f(num val) {}

  num operator [](int index) => 1;
  void operator []=(int index, num value) {}

  void testExtension() {
    // Note: in this test, the bare identifiers refer to the declarations in
    // this extension, so we expect them to behave differently from the
    // corresponding explicit uses of `this.`.
    if (this is B) {
      // 1. Simple member read
      x.expectStaticType<Exactly<num>>();
      this.x.expectStaticType<Exactly<int>>();

      // 2. Simple member write (without promotion, expects num)
      x = contextType(1.5)..expectStaticType<Exactly<num>>;
      this.x = contextType('hello')..expectStaticType<Exactly<Object>>;

      // 3. Method invocation (without promotion, expects num)
      f(contextType(1.5)..expectStaticType<Exactly<num>>);
      this.f(contextType('hello')..expectStaticType<Exactly<Object>>);
      bOnly(); // Ok because there is no `bOnly` in lexical scope.
      this.bOnly();

      // 4. Compound assignment
      (x += contextType(
        1,
      )..expectStaticType<Exactly<num>>).expectStaticType<Exactly<num>>();
      (x += 1).expectStaticType<Exactly<num>>();
      (this.x += contextType(
        1,
      )..expectStaticType<Exactly<num>>).expectStaticType<Exactly<num>>();
      (this.x += 1).expectStaticType<Exactly<int>>();

      // 5. Pre/post increment/decrement
      (x++).expectStaticType<Exactly<num>>();
      (++x).expectStaticType<Exactly<num>>();
      (this.x++).expectStaticType<Exactly<int>>();
      (++this.x).expectStaticType<Exactly<int>>();

      // 6. Null-aware assignment (without promotion, expects num?)
      (z ??= contextType(
        1,
      )..expectStaticType<Exactly<num?>>).expectStaticType<Exactly<num?>>();
      (z ??= 1).expectStaticType<Exactly<num>>();
      (this.z ??= contextType(1)..expectStaticType<Exactly<Object?>>)
          .expectStaticType<Exactly<Object?>>();
      (this.z ??= 1).expectStaticType<Exactly<int>>();

      // 7. Index operators
      this[0].expectStaticType<Exactly<int>>();
      this[0] = contextType('hello')..expectStaticType<Exactly<Object>>;
      (this[0] += contextType(
        1,
      )..expectStaticType<Exactly<num>>).expectStaticType<Exactly<num>>();
      (this[0] += 1).expectStaticType<Exactly<int>>();
      (this[0]++).expectStaticType<Exactly<int>>();
      (++this[0]).expectStaticType<Exactly<int>>();
    }
  }
}

main() {
  var obj = B();
  obj.testClass();
  obj.testExtension();
}
