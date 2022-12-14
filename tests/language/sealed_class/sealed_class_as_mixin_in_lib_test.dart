// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

// Allow mixing in a sealed class inside of library.

sealed class SealedClass {
  int nonAbstractFoo = 0;
  abstract int foo;
  int nonAbstractBar(int value) => value + 100;
  int bar(int value);
}
sealed mixin SealedMixin {}
class Class {}
mixin Mixin {}

abstract class A with SealedClass {}

class B with SealedClass {
  @override
  int nonAbstractFoo = 100;

  @override
  int foo = 2;

  @override
  int bar(int value) => value;
}

abstract class C = Object with SealedClass;

abstract class D with SealedClass, Class {}

class E with Class, SealedMixin {}

abstract class F with Mixin, SealedClass {}

class G with Mixin, Class {}
