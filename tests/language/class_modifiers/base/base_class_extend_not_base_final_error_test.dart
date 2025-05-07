// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Error when extending a base class where the subclass is not a base, final or
// sealed class.

import 'base_class_extend_lib.dart';

abstract class AOutside extends BaseClass {}
//             ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'AOutside' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.

class BOutside extends BaseClass {}
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] The type 'BOutside' must be 'base', 'final' or 'sealed' because the supertype 'BaseClass' is 'base'.
