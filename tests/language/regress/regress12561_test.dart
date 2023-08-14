// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C {
  noSuchMethod(int x, int y) => x + y;
//^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
// [cfe] The method 'C.noSuchMethod' has more required arguments than those of overridden method 'Object.noSuchMethod'.
  //               ^
  // [cfe] The parameter 'x' of the method 'C.noSuchMethod' has type 'int', which does not match the corresponding type, 'Invocation', in the overridden method, 'Object.noSuchMethod'.
}

main() {
  Expect.throws(() => new C().foo, (e) => e is Error);
  //                          ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'foo' isn't defined for the class 'C'.
}
