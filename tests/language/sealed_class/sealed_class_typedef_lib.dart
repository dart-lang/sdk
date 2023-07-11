// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Other-library declarations used by sealed_class_typedef_error_test.dart.

sealed class SealedClass {
  int foo = 0;
}

typedef SealedClassTypeDef = SealedClass;

class A extends SealedClassTypeDef {}

class B implements SealedClassTypeDef {
  int foo = 1;
}
