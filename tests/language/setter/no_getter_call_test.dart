// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

var topLevelClosure;

/*
get topLevel => topLevelClosure;
*/
set topLevel(var value) {}

initialize() {
  print("initializing");
  topLevelClosure = (x) => x * 2;
}

main() {
  initialize();
  var x = topLevelClosure(2);
  Expect.equals(4, x);

  x = topLevel(3);
  //  ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_FUNCTION
  // [cfe] Getter not found: 'topLevel'.
  Expect.equals(6, x);
}
