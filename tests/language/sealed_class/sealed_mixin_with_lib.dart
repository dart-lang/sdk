// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

sealed mixin SealedMixin {
  int nonAbstractFoo = 0;
  abstract int foo;
  int nonAbstractBar(int value) => value + 100;
  int bar(int value);
}

abstract class A with SealedMixin {}

class AImpl extends A {
  @override
  int foo = 1;

  @override
  int bar(int value) => value + 1;
}

class B with SealedMixin {
  @override
  int nonAbstractFoo = 100;
  
  @override
  int foo = 2;

  @override
  int bar(int value) => value;
}

abstract class C = Object with SealedMixin;

class CImpl extends C {
  @override
  int foo = 3;

  @override
  int bar(int value) => value - 1;
}
