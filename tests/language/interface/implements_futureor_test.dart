// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

class A<T> implements FutureOr<T> {}
//                    ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_DISALLOWED_TYPE
//    ^
// [cfe] The type 'FutureOr' can't be used in an 'implements' clause.

void main() {
  A a = new A();
}
