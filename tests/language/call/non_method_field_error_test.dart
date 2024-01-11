// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests calling an object's field which is not a method.

class Fisk {
  int i = 0;
}

class Hest extends Fisk {}

main() {
  Fisk x1 = new Fisk();
  x1.i();
//^^^^
// [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION
//    ^
// [cfe] 'i' isn't a function or method and can't be invoked.

  Hest x2 = new Hest();
  x2.i();
//^^^^
// [analyzer] COMPILE_TIME_ERROR.INVOCATION_OF_NON_FUNCTION_EXPRESSION
//    ^
// [cfe] 'i' isn't a function or method and can't be invoked.
}
