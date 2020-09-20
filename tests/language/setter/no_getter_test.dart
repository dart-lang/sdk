// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

set topLevel(var value) {}

class Example {
  set foo(var value) {}
}

main() {
  print(topLevel++);
  //    ^
  // [analyzer] unspecified
  // [cfe] Getter not found: 'topLevel'.

  Example ex = new Example();
  print(ex.foo++);
  //       ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'foo' isn't defined for the class 'Example'.
}
