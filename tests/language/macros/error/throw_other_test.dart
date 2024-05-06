// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// SharedOptions=--enable-experiment=macros

import 'impl/throw_other_macro.dart';

@ThrowOther(other: 'some unexpected error')
// [error line 8, column 1, length 43]
// [analyzer] COMPILE_TIME_ERROR.MACRO_ERROR
// [cfe] unspecified
class A {}
