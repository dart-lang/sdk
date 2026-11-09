// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests representation types, `implements` superinterfaces, unconstrained
// member signatures, usage in class member signatures, and subtyping for
// extension types with `out`, `in`, and `inout` variance modifiers.

// SharedOptions=--enable-experiment=variance

import "package:expect/expect.dart";

extension type Covariant<out X>(Object? covariantBase) {}

extension type Contravariant<in X>(Object? contravariantBase) {}

extension type Invariant<inout X>(Object? invariantBase) {}

extension type OutRepresentation<out T>(T it) implements Covariant<T> {
  void method(T x) {}
}

extension type InRepresentation<in T>(void Function(T) function)
    implements Contravariant<T> {
  T? get value => null;
}

extension type InoutRepresentation<inout T>(T Function(T) function)
    implements Invariant<T> {
  T method(T x) => x;
}

extension type InoutAnyPosition<inout T>(Object? it)
    implements Invariant<T>, Contravariant<T>, Covariant<T> {}

abstract class OutSignature<out T> {
  void method(Contravariant<T> x);
}

abstract class InSignature<in T> {
  Contravariant<T> get value;
}

void main() {
  Expect.subtype<OutRepresentation<int>, OutRepresentation<num>>();
  Expect.notSubtype<OutRepresentation<num>, OutRepresentation<int>>();

  Expect.subtype<InRepresentation<num>, InRepresentation<int>>();
  Expect.notSubtype<InRepresentation<int>, InRepresentation<num>>();

  Expect.notSubtype<InoutRepresentation<int>, InoutRepresentation<num>>();
  Expect.notSubtype<InoutRepresentation<num>, InoutRepresentation<int>>();

  Expect.subtype<InoutAnyPosition<int>, Covariant<num>>();
  Expect.subtype<InoutAnyPosition<num>, Contravariant<int>>();
}
