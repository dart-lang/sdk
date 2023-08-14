// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Other-library declarations used by sealed_class_implement_test.dart and
// sealed_class_implement_error_test.dart.

sealed class SealedClass {
  int nonAbstractFoo = 0;
  abstract int foo;
  int nonAbstractBar(int value) => value + 100;
  int bar(int value);
}

sealed class ClassForEnum {}

abstract class A implements SealedClass {}

class AImpl implements A {
  int nonAbstractFoo = 0;
  int foo = 1;
  int nonAbstractBar(int value) => value + 100;
  int bar(int value) => value + 1;
}

class B implements SealedClass {
  int nonAbstractFoo = 100;
  int foo = 2;
  int nonAbstractBar(int value) => value + 100;
  int bar(int value) => value;
}

enum EnumInside implements ClassForEnum { x }
