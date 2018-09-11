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

bool expectSubtype<Sub, Super>() {
  if (<Sub>[] is! List<Super>) {
    Expect.fail("$Sub is not a subtype of $Super");
  }
}

bool expectNotSubtype<Sub, Super>() {
  if (<Sub>[] is List<Super>) {
    Expect.fail("$Sub is a subtype of $Super");
  }
}

main() {
  expectSubtype<M, A>();
  expectSubtype<M, B>();
  expectSubtype<M, I>();
  expectSubtype<M, J>();
  expectSubtype<D, M>();
  expectSubtype<D, C>();
  expectNotSubtype<M, C>();
  expectNotSubtype<C, M>();

  expectSubtype<GM<int>, GA<int>>();
  expectSubtype<GM<int>, GB<int>>();
  expectSubtype<GM<int>, GI<int>>();
  expectSubtype<GM<int>, GJ<int>>();
  expectSubtype<GD<int>, GM<int>>();
  expectSubtype<GD<int>, GC<int>>();
  expectNotSubtype<GM<int>, GC<int>>();
  expectNotSubtype<GC<int>, GM<int>>();
}