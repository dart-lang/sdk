// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'static_access_without_static_members.dart' as p;

// Aliases of types that have neither static members nor constructors.
typedef F = void Function();
typedef void OldF();
typedef FG<T> = void Function(T);
typedef R = (int,);
typedef RN = (int,)?;
typedef RG<T> = (T,);
typedef FB<T extends num> = void Function(T);
typedef RB<T extends num> = (T,);
typedef D = dynamic;
typedef V = void;
typedef N = Never;

// An alias of a type variable, already reported for any selector.
typedef TV<T> = T;

// An alias of an invalid type, already reported at the declaration.
typedef Invalid = Unresolved;
typedef InvalidG<T> = Unresolved;

// A cyclic alias, already reported at the declaration.
typedef Cyclic = Cyclic;

// An alias of a class, a namespace of the class.
typedef CA<T> = C<T>;

class C<T> {
  static int s = 0;
}

extension on Type {
  int get typeGetter => 0;
}

void staticAccess() {
  F.hashCode; // Error.
  F.toString; // Error.
  F.toString(); // Error.
  F?.toString(); // Error.
  F.m<int>(); // Error.
  F.typeGetter; // Error.
  F.foo = 0; // Error.
  F.foo += 1; // Error.
  F.foo ??= 1; // Error.
  F.foo++; // Error.
  ++F.foo; // Error.
  OldF.hashCode; // Error.
  FG.hashCode; // Error.
  R.hashCode; // Error.
  RN.hashCode; // Error.
  RG.hashCode; // Error.
  D.toString(); // Error.
  V.hashCode; // Error.
  N.hashCode; // Error.
  p.F.toString(); // Error.
  p.R.hashCode; // Error.
}

void constructorReference() {
  FG<int>.hashCode; // Error.
  FG<int>.m<int>(); // Error.
  RG<int>.hashCode; // Error.
  RG<int>.foo = 0; // Error.
  p.RG<int>.hashCode; // Error.
  FB<String>.hashCode; // Error, and type argument bound error.
  RB<String>.hashCode; // Error, and type argument bound error.
  p.FB<String>.hashCode; // Error, and type argument bound error.
}

void aliasOfTypeVariable() {
  TV.hashCode; // Error.
  TV<int>.hashCode; // Error.
}

void aliasOfInvalidType() {
  Invalid.hashCode; // No error here, reported at the declaration.
  InvalidG<int>.hashCode; // No error here, reported at the declaration.
}

void cyclicAlias() {
  Cyclic.hashCode; // No error here, reported at the declaration.
}

void aliasOfClass() {
  CA.s; // Ok.
  CA.hashCode; // Error.
}

void typeObject() {
  (F).hashCode; // Ok.
  (F).typeGetter; // Ok.
  (RG<int>).hashCode; // Ok.
  F..hashCode; // Ok.
  Type t = RG<int>;
  t.hashCode; // Ok.
}

main() {}
