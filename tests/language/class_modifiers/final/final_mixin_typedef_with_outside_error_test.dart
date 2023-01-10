// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when attempting to mix in a typedef final mixin outside of library.

import 'final_mixin_typedef_with_lib.dart';

abstract class AOutside with FinalMixinTypeDef {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

class BOutside with FinalMixinTypeDef {}
// ^
// [analyzer] unspecified
// [cfe] unspecified
