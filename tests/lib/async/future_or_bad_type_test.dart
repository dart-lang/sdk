// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// In non strong-mode, `FutureOr<T>` is dynamic, even if `T` doesn't exist.
// `FutureOr<T>` can not be used as superclass, mixin, nor can it be
// implemented (as interface).

import 'dart:async';
import 'package:expect/expect.dart';

class A extends FutureOr<String> {}
//    ^
// [cfe] The superclass, 'FutureOr', has no unnamed constructor that takes no arguments.
//              ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

class B with FutureOr<bool> {}
//    ^
// [cfe] Can't use 'FutureOr' as a mixin because it has constructors.
//           ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE
// [cfe] The class 'FutureOr' can't be used as a mixin because it isn't a mixin class nor a mixin.

class C implements FutureOr<int> {}
//    ^
// [cfe] The type 'FutureOr' can't be used in an 'implements' clause.
//                 ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE

main() {}
