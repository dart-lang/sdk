// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*Debugger:stepOver*/

class Class2 {
  dynamic operator [](index) => index;

  dynamic code() {
    /*bl*/ /*sl:1*/ this[42]; // DDK fails to hover on `this`
    return /*sl:2*/ this[42];
  }
}

void main() {
  var c = Class2();
  c[42];
  c.code();
}
