// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Other-library declarations used by sealed_class_extend_test.dart and
// sealed_class_extend_error_test.dart.

sealed class SealedClass {
  int nonAbstractFoo = 0;
  abstract int foo;
  int nonAbstractBar(int value) => value + 100;
  int bar(int value);
}

abstract class A extends SealedClass {}

class AImpl extends A {
  int foo = 1;
  int bar(int value) => value + 1;
}

class B extends SealedClass {
  int nonAbstractFoo = 100;
  int foo = 2;
  int bar(int value) => value;
}
