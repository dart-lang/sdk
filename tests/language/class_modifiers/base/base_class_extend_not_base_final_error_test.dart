// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when extending a base class where the subclass is not also a base class
// or final.

import 'base_class_extend_lib.dart';

abstract class AOutside extends BaseClass {}
// ^
// [analyzer] unspecified
// [cfe] unspecified

class BOutside extends BaseClass {}
// ^
// [analyzer] unspecified
// [cfe] unspecified
