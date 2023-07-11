// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.19

// Make sure errors are emitted when trying to use sealed classes without
// the `sealed` experiment enabled.

sealed class SealedClass {
// [error column 1, length 6]
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'sealed-class' language feature is disabled for this library.
//           ^
// [cfe] The non-abstract class 'SealedClass' is missing implementations for these members:
  int nonAbstractFoo = 0;
  abstract int foo;
//^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER
  int nonAbstractBar(int value) => value + 100;
  int bar(int value);
//^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONCRETE_CLASS_WITH_ABSTRACT_MEMBER
}

mixin M {}
sealed class SealedClassTypeAlias = Object with M;
// [error column 1, length 6]
// [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
// [cfe] The 'sealed-class' language feature is disabled for this library.
