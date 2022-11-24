// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

// Error when attempting to extend a sealed class outside of its library.

import 'sealed_class_extend_lib.dart';

abstract class OutsideA extends SealedClass {}
//             ^
// [analyzer] unspecified
// [cfe] Sealed class 'SealedClass' can't be extended, implemented, or mixed in outside of its library.

class OutsideB extends SealedClass {
//    ^
// [analyzer] unspecified
// [cfe] Sealed class 'SealedClass' can't be extended, implemented, or mixed in outside of its library.
  @override
  int foo = 2;

  @override
  int bar(int value) => value;
}
