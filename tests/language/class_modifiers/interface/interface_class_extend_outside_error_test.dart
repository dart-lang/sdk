// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when attempting to extend an interface class outside of library.

import 'interface_class_extend_lib.dart';

abstract class AOutside extends InterfaceClass {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

class BOutside extends InterfaceClass {
// ^
// [analyzer] unspecified
// [cfe] unspecified
}
