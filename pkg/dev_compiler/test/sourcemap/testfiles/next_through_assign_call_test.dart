// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*Debugger:stepOver*/
void main() {
  /*nb*/ int a;
  /*nb*/ int b;
  a = b = /*bc:1*/ foo();
  /*bc:2*/ print(a);
  /*bc:3*/ print(b);
  a = /*bc:4*/ foo();
  /*bc:5*/ print(a);
  var d = /*bc:6*/ foo();
  /*bc:7*/ print(d);
  int e = /*bc:8*/ foo(), f, g = /*bc:9*/ foo();
  /*bc:10*/ print(e);
  /*bc:11*/ print(f);
  /*bc:12*/ print(g);
}

int foo() {
  return 42;
}
