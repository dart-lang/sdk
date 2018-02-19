// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*Debugger:stepOver*/

class Class2 {
  operator [](index) => index;

  code() {
    /*bl*/ /*sl:1*/ this[42]; // DDK fails to hover on `this`
    return /*sl:2*/ this[42];
  }
}

main() {
  Class2 c = new Class2();
  c[42];
  c.code();
}
