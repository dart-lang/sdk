// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// A mixin declaration introduces a type.

// A mixin with multiple super-types and implemented types.
class A {}
class B {}
class I {}
class J {}

mixin M on A, B implements I, J {}

class C implements A, B {}

class D = C with M;

// Same, with generics.
class GA<T> {}
class GB<T> {}
class GI<T> {}
class GJ<T> {}

mixin GM<T> on GA<T>, GB<List<T>> implements GI<Iterable<T>>, GJ<Set<T>> {}

class GC<T> implements GA<T>, GB<List<T>> {}

class GD<T> = GC<T> with GM<T>;

main() {
  Expect.subtype<M, A>();
  Expect.subtype<M, B>();
  Expect.subtype<M, I>();
  Expect.subtype<M, J>();
  Expect.subtype<D, M>();
  Expect.subtype<D, C>();
  Expect.notSubtype<M, C>();
  Expect.notSubtype<C, M>();

  Expect.subtype<GM<int>, GA<int>>();
  Expect.subtype<GM<int>, GB<List<int>>>();
  Expect.subtype<GM<int>, GI<Iterable<int>>>();
  Expect.subtype<GM<int>, GJ<Set<int>>>();
  Expect.subtype<GD<int>, GM<int>>();
  Expect.subtype<GD<int>, GC<int>>();
  Expect.notSubtype<GM<int>, GC<int>>();
  Expect.notSubtype<GC<int>, GM<int>>();
}