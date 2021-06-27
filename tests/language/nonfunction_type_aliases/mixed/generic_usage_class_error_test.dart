// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart = 2.9
// Requirements=nnbd-weak


// Test that a type alias `T` denoting a class
// can give rise to the expected errors.

import 'dart:async';
import 'generic_usage_class_error_lib.dart';

// Use the aliased type.

abstract class C {}

abstract class D2 extends C with T<int> {}
//             ^
// [analyzer] unspecified
// [cfe] unspecified

abstract class D4 = C with T<void>;
//             ^
// [analyzer] unspecified
// [cfe] unspecified

main() {
  T<List<List<List<List>>>>.staticMethod<T<int>>();
  //                        ^
  // [analyzer] unspecified
  // [cfe] unspecified
}
