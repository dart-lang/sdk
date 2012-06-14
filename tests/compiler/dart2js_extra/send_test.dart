// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int foo() {
    return 42;
  }
}

void main() {
  int i = new A().foo();
  print(i);
  if (i == 42) {
    print('pass');
  } else {
    throw "error";
  }
}
