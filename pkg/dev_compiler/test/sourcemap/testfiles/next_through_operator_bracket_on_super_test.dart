// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*Debugger:stepOver*/

class Class2 {
  dynamic operator [](index) => index;

  dynamic code() {
    this[42];
    return this[42];
  }
}

class Class3 extends Class2 {
  @override
  dynamic code() {
    /*bl*/ /*sl:1*/ super[42];
    /*sl:2*/ return super[42];
  }
}

void main() {
  var c = Class3();
  c[42];
  c.code();
}
