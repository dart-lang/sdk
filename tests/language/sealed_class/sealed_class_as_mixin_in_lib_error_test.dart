// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

// Error when attempting to mix in a sealed class inside of library.

sealed class SealedClass {
  int nonAbstractFoo = 0;
  abstract int foo;
  int nonAbstractBar(int value) => value + 100;
  int bar(int value);
}

abstract class A with SealedClass {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

class B with SealedClass {
// ^
// [analyzer] unspecified
// [cfe] unspecified
  @override
  int nonAbstractFoo = 100;

  @override
  int foo = 2;

  @override
  int bar(int value) => value;
}

abstract class C = Object with SealedClass;
// ^
// [analyzer] unspecified
// [cfe] unspecified
