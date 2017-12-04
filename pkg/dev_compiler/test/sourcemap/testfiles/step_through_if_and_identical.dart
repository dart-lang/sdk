// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*Debugger:stepOver*/

main() {
  if (/*bc:1*/ foo() /*bc:3*/ == /*bc:2*/ bar()) {
    print("wat?!?");
  }
  if (identical(/*bc:4*/ foo(), /*bc:5*/ bar())) {
    print("wat?!?");
  }
}

foo() {
  return 42;
}

bar() {
  return 43;
}
