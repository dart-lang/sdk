// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// For `==` and `!=` with a dot shorthand on the right, the static type of the
// LHS provides the context type for the RHS. The type arguments for the RHS
// are inferred.
//
// Regression test for https://github.com/dart-lang/sdk/issues/64751.

import 'package:expect/expect.dart';

class Foo<T> {
  Foo();

  static Foo<T> of<T>(T value) => Foo<T>();

  static Foo<T> bounded<T extends String>() => Foo<T>();

  @override
  bool operator ==(Object other) => other is Foo<T>;
}

void main() {
  Foo<int> foo = Foo();

  bool equalsOf = foo == Foo.of('a');
  bool equalsOfShorthand = foo == .of('a');
  Expect.equals(equalsOf, equalsOfShorthand);

  bool notEqualsOf = foo != Foo.of('a');
  bool notEqualsOfShorthand = foo != .of('a');
  Expect.equals(notEqualsOf, notEqualsOfShorthand);

  bool equalsBounded = foo == Foo.bounded();
  bool equalsBoundedShorthand = foo == .bounded();
  Expect.equals(equalsBounded, equalsBoundedShorthand);

  bool equalsNew = foo == Foo();
  bool equalsNewShorthand = foo == .new();
  Expect.equals(equalsNew, equalsNewShorthand);

  bool equalsListOfString = [3] == List.of(['a']);
  bool equalsListOfStringShorthand = [3] == .of(['a']);
  Expect.equals(equalsListOfString, equalsListOfStringShorthand);

  bool equalsListOfDouble = [3] == List.of([3.5]);
  bool equalsListOfDoubleShorthand = [3] == .of([3.5]);
  Expect.equals(equalsListOfDouble, equalsListOfDoubleShorthand);
}
