// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

var c = () {
  throw "Baz";
};

class C {
  static var d = () {
    throw "Baz";
  };
  var e = () {
    throw "Baz";
  };
}

void test() {
  var a = () {
    throw "Hello";
  };
  b() {
    throw "World";
  }

  int x;
  x = a();
  x = b();
  x = c();
  x = C.d();
  x = C().e();
}
