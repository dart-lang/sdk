// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*Debugger:stepOver*/

class Class2 {
  operator [](index) => index;

  code() {
    this[42];
    return this[42];
  }
}

main() {
  /*bl*/ /*sl:1*/ Class2 c = new Class2();
  c /*sl:2*/ [42];
  c /*sl:3*/ .code();
}
