// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*Debugger:stepOver*/

main() {
  print(/*bc:1*/ foo() ? bar() : /*bc:2*/ baz());
  print(/*bc:4*/ ! /*bc:3*/ foo() ? /*bc:5*/ bar() : baz());
}

foo() {
  return false;
}

bar() {
  return "bar";
}

baz() {
  return "baz";
}
