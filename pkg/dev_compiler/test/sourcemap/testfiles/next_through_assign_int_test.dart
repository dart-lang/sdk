// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*Debugger:stepOver*/
void main() {
  /*nb*/ int a;
  /*nb*/ int b;
  /*bl*/
  /*s:1*/ a = b = 42;
  /*s:2*/ print(a);
  /*s:3*/ print(b);
  /*s:4*/ a = 42;
  /*s:5*/ print(a);
  var d = /*s:6*/ 42;
  /*s:7*/ print(d);
  int e = /*s:8*/ 41, f, g = /*s:9*/ 42;
  /*s:10*/ print(e);
  /*s:11*/ print(f);
  /*s:12*/ print(g);
}
