// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo(int arg) {}

class C {
  C(int arg) {}
  static foo(int arg) {}
}

var a;

int get getter => 42;

void set setter(int arg) {
  a = 10;
}

var list = new List<int>();

var closure = (int arg) => 3;
