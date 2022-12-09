// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

// Error when attempting to mix in a sealed mixin outside of its library.

import 'sealed_mixin_with_lib.dart';

abstract class OutsideA with SealedMixin {}
// [error column 1, length 43]
// [analyzer] COMPILE_TIME_ERROR.SEALED_MIXIN_SUBTYPE_OUTSIDE_OF_LIBRARY
//             ^
// [cfe] Sealed mixin 'SealedMixin' can't be mixed in outside of its library.

class OutsideB with SealedMixin {
// [error column 1, length 218]
// [analyzer] COMPILE_TIME_ERROR.SEALED_MIXIN_SUBTYPE_OUTSIDE_OF_LIBRARY
//    ^
// [cfe] Sealed mixin 'SealedMixin' can't be mixed in outside of its library.
  @override
  int foo = 2;

  @override
  int bar(int value) => value;
}

abstract class OutsideC = Object with SealedMixin;
// [error column 1, length 50]
// [analyzer] COMPILE_TIME_ERROR.SEALED_MIXIN_SUBTYPE_OUTSIDE_OF_LIBRARY
//             ^
// [cfe] Sealed mixin 'SealedMixin' can't be mixed in outside of its library.
