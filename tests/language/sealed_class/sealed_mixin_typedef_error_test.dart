// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

// Error when attempting to mix in a typedef sealed mixin outside of its library

import 'sealed_mixin_typedef_lib.dart';

class ATypeDef with SealedMixinTypeDef {}
//                  ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The mixin 'SealedMixin' can't be mixed in outside of its library because it's a sealed mixin.
