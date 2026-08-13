// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests the functionality proposed in
// https://github.com/dart-lang/language/issues/1618#issuecomment-1507241494,
// using if-null assignments whose target is an index expression whose target is
// `this`.

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

class Indexable<ReadType, WriteType> {
  final ReadType _value;

  Indexable(this._value);

  ReadType operator [](int index) => _value;

  operator []=(int index, WriteType value) {}
}

class Test1 extends Indexable<C1<int>?, Object?> {
  Test1() : super(null);
  test() {
    var c2Double = C2<double>();
    contextB1(this[0] ??= c2Double);
  }
}

class Test2 extends Indexable<Iterable<int>?, Object?> {
  Test2() : super(null);
  test() {
    var listNum = <num>[];
    contextIterable<num>(this[0] ??= listNum);
  }
}

main() {
  Test1().test();
  Test2().test();
}
