// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when mixing in a base mixin where the class mixing it in is not base or
// final.

import 'base_mixin_with_lib.dart';

abstract class AOutside with BaseMixin {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

class BOutside with BaseMixin {}
// ^
// [analyzer] unspecified
// [cfe] unspecified
