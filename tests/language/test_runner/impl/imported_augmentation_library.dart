// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--enable-experiment=macros

library augment '../imported_augmentation_library_failure_test.dart';

class A
//    ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_BODY
// [cfe] A class declaration must have a body, even if it is empty.

