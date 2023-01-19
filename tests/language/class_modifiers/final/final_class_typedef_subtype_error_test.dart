// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when attempting to implement or extend a typedef final class outside of
// its library.

import 'final_class_typedef_lib.dart';

class ATypeDef extends FinalClassTypeDef {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

class BTypeDef implements FinalClassTypeDef {
// ^
// [analyzer] unspecified
// [cfe] unspecified
  @override
  int foo = 1;
}
