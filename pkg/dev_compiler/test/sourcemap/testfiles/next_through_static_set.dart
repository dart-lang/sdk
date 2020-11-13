// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*Debugger:stepOver*/

var bar = 0;

void main() {
  bar = /*bc:1*/ foo();
}

int foo() {
  return 42;
}
