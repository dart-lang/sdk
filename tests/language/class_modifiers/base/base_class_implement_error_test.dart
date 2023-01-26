// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when attempting to implement base class outside of library.

import 'base_class_implement_lib.dart';

abstract class AOutside implements BaseClass {}
//             ^
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.
// [analyzer] unspecified

class BOutside implements BaseClass {
//    ^
// [cfe] The class 'BaseClass' can't be implemented outside of its library because it's a base class.
// [analyzer] unspecified
  @override
  int foo = 1;
}
