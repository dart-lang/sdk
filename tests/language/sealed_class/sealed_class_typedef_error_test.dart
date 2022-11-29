// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

// Error when attempting to extend or implement typedef sealed class
// outside of its library.

import 'sealed_class_typedef_lib.dart';

class ATypeDef extends SealedClassTypeDef {}
//    ^
// [analyzer] unspecified
// [cfe] Sealed class 'SealedClass' can't be extended, implemented, or mixed in outside of its library.

class BTypeDef implements SealedClassTypeDef {
//    ^
// [analyzer] unspecified
// [cfe] Sealed class 'SealedClass' can't be extended, implemented, or mixed in outside of its library.
  @override
  int foo = 1;
}
