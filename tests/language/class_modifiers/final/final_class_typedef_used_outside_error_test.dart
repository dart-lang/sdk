// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when trying to implement or extend a typedef final class outside of
// the final class' library when the typedef is also outside the final class
// library.

import 'final_class_typedef_used_outside_lib.dart';

typedef ATypeDef = FinalClass;

class A extends ATypeDef {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

class B implements ATypeDef {
// ^
// [analyzer] unspecified
// [cfe] unspecified
  int foo = 1;
}
