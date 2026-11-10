// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests member signatures, `with` and `implements` superinterfaces, and
// subtyping for enums with `out`, `in`, and `inout` variance modifiers.

// SharedOptions=--enable-experiment=variance

import "package:expect/expect.dart";

class Covariant<out T> {}

class Contravariant<in T> {}

class Invariant<inout T> {}

mixin MCovariant<out T> {}

mixin MContravariant<in T> {}

mixin MInvariant<inout T> {}

enum OutEnum<out T> with MCovariant<T> implements Covariant<T> {
  a;

  T? get value => null;
}

enum InEnum<in T> with MContravariant<T> implements Contravariant<T> {
  a;

  void method(T x) {}
}

enum InoutEnum<inout T> with MInvariant<T> implements Invariant<T> {
  a;

  T method(T x) => x;
}

enum InoutAnyPosition<inout T>
    with MInvariant<T>, MContravariant<T>, MCovariant<T>
    implements Invariant<T>, Contravariant<T>, Covariant<T> {
  a,
}

void main() {
  Expect.subtype<OutEnum<int>, OutEnum<num>>();
  Expect.notSubtype<OutEnum<num>, OutEnum<int>>();

  Expect.subtype<InEnum<num>, InEnum<int>>();
  Expect.notSubtype<InEnum<int>, InEnum<num>>();

  Expect.notSubtype<InoutEnum<int>, InoutEnum<num>>();
  Expect.notSubtype<InoutEnum<num>, InoutEnum<int>>();

  Expect.subtype<InoutAnyPosition<int>, MCovariant<num>>();
  Expect.subtype<InoutAnyPosition<num>, MContravariant<int>>();
  Expect.notSubtype<InoutAnyPosition<int>, MInvariant<num>>();

  Expect.subtype<InoutAnyPosition<int>, Covariant<num>>();
  Expect.subtype<InoutAnyPosition<num>, Contravariant<int>>();
  Expect.notSubtype<InoutAnyPosition<int>, Invariant<num>>();
}
