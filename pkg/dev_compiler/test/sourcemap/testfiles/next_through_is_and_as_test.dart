// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*Debugger:stepOver*/

main() {
  /*bl*/
  /*sl:1*/ var i = 42.42;
  /*sl:2*/ var hex = 0x42;
  if (/*bc:3*/ foo() /*bc:4*/ is int) {
    /*bc:5*/ print("foo is int");
  }
  if (i /*bc:6*/ is int) {
    print("i is int");
  }
  if (i /*bc:7*/ is! int) {
    /*bc:8*/ print("i is not int");
  }
  if (hex /*bc:9*/ is int) {
    /*bc:10*/ print("hex is int");
    int x = hex /*bc:11*/ as int;
    if (x. /*bc:12*/ isEven) {
      /*bc:13*/ print("it's even even!");
    } else {
      print("but it's not even even!");
    }
  }
  if (hex /*bc:14*/ is! int) {
    print("hex is not int");
  }
}

foo() => 42;
