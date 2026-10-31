// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests member signatures, `implements` superinterfaces, and subtyping for
// mixin classes with `out`, `in`, and `inout` variance modifiers.

// SharedOptions=--enable-experiment=variance

import "package:expect/expect.dart";

class Covariant<out T> {}

class Contravariant<in T> {}

class Invariant<inout T> {}

mixin class OutMixinClass<out T> implements Covariant<T> {
  T? get value => null;
}

mixin class InMixinClass<in T> implements Contravariant<T> {
  void method(T x) {}
}

mixin class InoutMixinClass<inout T> implements Invariant<T> {
  T method(T x) => x;
}

mixin class InoutAnyPosition<inout T>
    implements Invariant<T>, Contravariant<T>, Covariant<T> {}

void main() {
  Expect.subtype<OutMixinClass<int>, OutMixinClass<num>>();
  Expect.notSubtype<OutMixinClass<num>, OutMixinClass<int>>();

  Expect.subtype<InMixinClass<num>, InMixinClass<int>>();
  Expect.notSubtype<InMixinClass<int>, InMixinClass<num>>();

  Expect.notSubtype<InoutMixinClass<int>, InoutMixinClass<num>>();
  Expect.notSubtype<InoutMixinClass<num>, InoutMixinClass<int>>();

  Expect.subtype<InoutAnyPosition<int>, Covariant<num>>();
  Expect.subtype<InoutAnyPosition<num>, Contravariant<int>>();
  Expect.notSubtype<InoutAnyPosition<int>, Invariant<num>>();
}
