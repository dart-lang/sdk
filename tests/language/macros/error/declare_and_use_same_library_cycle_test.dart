// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--enable-experiment=macros
import 'impl/macro_in_library_cycle.dart';

@AnyMacro()
// [error line 7, column 1]
// [analyzer] unspecified
// [cfe] unspecified
class A {}

// So this import is not unused.
int get someValue => 0;
