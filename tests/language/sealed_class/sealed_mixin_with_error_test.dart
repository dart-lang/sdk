// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

// Error when attempting to mix in a sealed mixin outside of its library.

import 'sealed_mixin_with_lib.dart';

abstract class OutsideA with SealedMixin {}
//             ^
// [analyzer] unspecified
// [cfe] Sealed mixin 'SealedMixin' can't be mixed in outside of its library.

class OutsideB with SealedMixin {
//    ^
// [analyzer] unspecified
// [cfe] Sealed mixin 'SealedMixin' can't be mixed in outside of its library.
  @override
  int foo = 2;

  @override
  int bar(int value) => value;
}

abstract class OutsideC = Object with SealedMixin;
//             ^
// [analyzer] unspecified
// [cfe] Sealed mixin 'SealedMixin' can't be mixed in outside of its library.
