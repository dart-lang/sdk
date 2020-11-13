// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*Debugger:stepOver*/

void main() {
  /*bl*/
  var x = {/*bc:1*/ foo(): /*bc:2*/ bar() };
  /*sl:3*/ print(x);
}

int foo() {
  return 42;
}

int bar() {
  return 2;
}
