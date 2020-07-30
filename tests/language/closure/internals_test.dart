// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class C {
  foo() => 123;
}

main() {
  var f = new C().foo;
  var target = f.target;
  //             ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'target' isn't defined for the class 'dynamic Function()'.
  var self = f.self;
  //           ^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'self' isn't defined for the class 'dynamic Function()'.
  var receiver = f.receiver;
  //               ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'receiver' isn't defined for the class 'dynamic Function()'.
}
