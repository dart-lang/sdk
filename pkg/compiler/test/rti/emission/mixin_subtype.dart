// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// Derived from language_2/mixin_declaration/mixin_declaration_subtype_test.

import "package:compiler/src/util/testing.dart";

// A mixin declaration introduces a type.

// A mixin with multiple super-types and implemented types.

/*class: A:checkedInstance,typeArgument*/
class A {}

/*class: B:checkedInstance,typeArgument*/
class B {}

/*class: I:checkedInstance,typeArgument*/
class I {}

/*class: J:checkedInstance,typeArgument*/
class J {}

/*class: M1:checkedInstance,typeArgument*/
mixin M1 on A, B implements I, J {}

/*class: M2:checkedInstance,checks=[$isA,$isB,$isI,$isJ],typeArgument*/
class M2 implements A, B, I, J {}

/*class: M3:checkedInstance,checks=[$isA,$isB,$isI,$isJ],instance,typeArgument*/
class M3 implements A, B, I, J {}

/*class: M4:checkedInstance,checks=[$isA,$isB,$isI,$isJ],typeArgument*/
class M4 implements A, B, I, J {}

/*class: M5:checkedInstance,checks=[$isA,$isB,$isI,$isJ],typeArgument*/
class M5 implements A, B, I, J {}

/*class: C:checkedInstance,checks=[$isA,$isB],indirectInstance,typeArgument*/
class C implements A, B {}

/*class: D1:checkedInstance,typeArgument*/
class D1 = C with M1;

/*class: D2:checkedInstance,checks=[$isI,$isJ],instance,typeArgument*/
class D2 = C with M2;

/*class: D3:checkedInstance,typeArgument*/
class D3 = C with M3;

/*class: D4:checkedInstance,checks=[$isI,$isJ],instance,typeArgument*/
class D4 extends C with M4 {}

/*class: D5:checkedInstance,checks=[$isI,$isJ],indirectInstance,typeArgument*/
class D5 extends C with M5 {}

/*class: E5:checkedInstance,checks=[],instance,typeArgument*/
class E5 extends D5 {}

// Same, with generics.
/*class: GA:checkedInstance,typeArgument*/
class GA<T> {}

/*class: GB:checkedInstance,typeArgument*/
class GB<T> {}

/*class: GI:checkedInstance,typeArgument*/
class GI<T> {}

/*class: GJ:checkedInstance,typeArgument*/
class GJ<T> {}

/*class: GM:checkedInstance,typeArgument*/
mixin GM<T> on GA<T>, GB<List<T>> implements GI<Iterable<T>>, GJ<Set<T>> {}

/*class: GC:checkedInstance,typeArgument*/
class GC<T> implements GA<T>, GB<List<T>> {}

/*class: GD:checkedInstance,typeArgument*/
class GD<T> = GC<T> with GM<T>;

main() {
  makeLive(new M3());
  makeLive(new D2());
  makeLive(new D4());
  makeLive(new E5());
  subtype<M1, A>();
  subtype<M1, B>();
  subtype<M1, I>();
  subtype<M1, J>();
  subtype<D1, M1>();
  subtype<D2, M2>();
  subtype<D3, M3>();
  subtype<D4, M4>();
  subtype<D5, M5>();
  subtype<E5, M5>();
  notSubtype<M1, C>();
  notSubtype<C, M1>();

  subtype<GM<int>, GA<int>>();
  subtype<GM<int>, GB<List<int>>>();
  subtype<GM<int>, GI<Iterable<int>>>();
  subtype<GM<int>, GJ<Set<int>>>();
  subtype<GD<int>, GM<int>>();
  subtype<GD<int>, GC<int>>();
  notSubtype<GM<int>, GC<int>>();
  notSubtype<GC<int>, GM<int>>();
}
