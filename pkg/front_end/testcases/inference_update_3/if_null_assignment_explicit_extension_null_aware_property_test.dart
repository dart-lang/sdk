// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the functionality proposed in
// https://github.com/dart-lang/language/issues/1618#issuecomment-1507241494,
// using if-null assignments whose target is a null-aware access to an extension
// property, using explicit extension syntax.

/// Ensures a context type of `Iterable<T>?` for the operand, or `Iterable<_>?`
/// if no type argument is supplied.
Iterable<T>? contextIterableQuestion<T>(Iterable<T>? x) => x;

class A {}

class B1<T> implements A {}

class B2<T> implements A {}

class C1<T> implements B1<T>, B2<T> {}

class C2<T> implements B1<T>, B2<T> {}

/// Ensures a context type of `B1<T>?` for the operand, or `B1<_>?` if no type
/// argument is supplied.
B1<T>? contextB1Question<T>(B1<T>? x) => x;

extension Extension on String {
  C1<int>? get pC1IntQuestion => null;
  set pC1IntQuestion(Object? value) {}
  Iterable<int>? get pIterableIntQuestion => null;
  set pIterableIntQuestion(Object? value) {}
}

main() {
  var s = '' as String?;

  var c2Double = C2<double>();
  contextB1Question(Extension(s)?.pC1IntQuestion ??= c2Double);

  var listNum = <num>[];
  contextIterableQuestion<num>(Extension(s)?.pIterableIntQuestion ??= listNum);
}
