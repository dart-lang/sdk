// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*Debugger:stepOver*/

void main() {
  /*bl*/
  try {
    /*sl:1*/ var value = 'world';
    // Comment
    /*sl:2*/ /*nbb:2:7*/ throw 'Hello, $value';
  }
  // Comment
  catch (e, /*s:3*/ st) {
    /*sl:4*/ print(e);
    /*sl:5*/ print(st);
  }
  try {
    // Comment
    /*sl:6*/ /*nbb:6:7*/ throw 'Hello, world';
  } catch (e) {
    /*sl:7*/ print(e);
  }
}
