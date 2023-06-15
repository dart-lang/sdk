// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Other-library declarations used by sealed_class_as_mixin_error_test.dart.

sealed class SealedClass {
  int nonAbstractFoo = 0;
  abstract int foo;
  int nonAbstractBar(int value) => value + 100;
  int bar(int value);
}

class Class {}

mixin Mixin {}
