// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*Debugger:stepOver*/
void main() {
  /*nb*/ int a;
  /*nb*/ int b;
  /*bl*/
  a = /*s:1*/ b = 42;
  /*s:2*/ print(a);
  /*s:3*/ print(b);
  /*s:4*/ a = 42;
  /*s:5*/ print(a);
  var d = /*s:6*/ 42;
  /*s:7*/ print(d);
  int? e = /*s:8*/ 41, /*s:9*/ f, g = /*s:10*/ 42;
  /*s:11*/ print(e);
  /*s:12*/ print(f);
  /*s:13*/ print(g);
}
