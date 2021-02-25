// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

/// It is a compile-time error if a named formal parameter begins with an '_'.

class Foo {
  num _y;
  Foo.private({this._y: 77}) {}
  //                ^^
  // [analyzer] COMPILE_TIME_ERROR.PRIVATE_OPTIONAL_PARAMETER
  //                ^
  // [cfe] An optional named parameter can't start with '_'.
}

main() {
  Foo.private(_y: 222);
}
