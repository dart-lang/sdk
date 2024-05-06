// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the functionality proposed in
// https://github.com/dart-lang/language/issues/1618#issuecomment-1507241494,
// using if-null assignments whose target is a property of the current
// extension, accessed through explicit `this` using explicit extension syntax.

/// Ensures a context type of `Iterable<T>` for the operand, or `Iterable<_>` if
/// no type argument is supplied.
Iterable<T> contextIterable<T>(Iterable<T> x) => x;

class A {}

class B1<T> implements A {}

class B2<T> implements A {}

class C1<T> implements B1<T>, B2<T> {}

class C2<T> implements B1<T>, B2<T> {}

/// Ensures a context type of `B1<T>` for the operand, or `B1<_>` if no type
/// argument is supplied.
B1<T> contextB1<T>(B1<T> x) => x;

extension Extension on String {
  C1<int>? get pC1IntQuestion => null;
  set pC1IntQuestion(Object? value) {}
  Iterable<int>? get pIterableIntQuestion => null;
  set pIterableIntQuestion(Object? value) {}

  test() {
    var c2Double = C2<double>();
    contextB1(Extension(this).pC1IntQuestion ??= c2Double);

    // K=Iterable<num>, T1=Iterable<int>?, and T2=List<num>, therefore
    // T=Object and S=Iterable<num>, so T is not <: S, but NonNull(T1) <: S
    // and T2 <: S, hence the type of E is Iterable<num>.
    var listNum = <num>[];
    contextIterable<num>(Extension(this).pIterableIntQuestion ??= listNum);
  }
}

main() {
  ''.test();
}
