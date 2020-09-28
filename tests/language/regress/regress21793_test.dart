// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for issue 21793.

import 'package:expect/expect.dart';

/*
class A {
  call(x) => x;
}
*/

main() {
  print(new A()(499));
  //        ^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  // [cfe] Method not found: 'A'.
}
