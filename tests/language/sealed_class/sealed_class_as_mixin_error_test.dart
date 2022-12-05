// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

// Error when attempting to mix in a sealed class outside of library.

import 'sealed_class_as_mixin_in_lib_error_test.dart';

abstract class OutsideA with SealedClass {}
//             ^
// [analyzer] unspecified
// [cfe] Sealed class 'SealedClass' can't be extended, implemented, or mixed in outside of its library.

class OutsideB with SealedClass {
//    ^
// [analyzer] unspecified
// [cfe] Sealed class 'SealedClass' can't be extended, implemented, or mixed in outside of its library.
  @override
  int foo = 2;

  @override
  int bar(int value) => value;
}

abstract class OutsideC = Object with SealedClass;
//             ^
// [analyzer] unspecified
// [cfe] Sealed class 'SealedClass' can't be extended, implemented, or mixed in outside of its library.
