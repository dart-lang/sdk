// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when mixing in a base mixin where the class mixing it in is not base,
// final, or sealed.

import 'base_mixin_with_lib.dart';

abstract class AOutside with BaseMixin {}
//             ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'AOutside' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.

class BOutside with BaseMixin {}
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'BOutside' must be 'base', 'final' or 'sealed' because the supertype 'BaseMixin' is 'base'.
