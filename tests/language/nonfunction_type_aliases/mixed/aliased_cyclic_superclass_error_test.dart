// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart = 2.9
// Requirements=nnbd-weak


// Test that a type alias `T` denoting a class
// can give rise to the expected errors.

import 'aliased_cyclic_superclass_error_lib.dart';

class C extends T {}
//    ^
// [analyzer] unspecified
// [cfe] unspecified

main() => C();
