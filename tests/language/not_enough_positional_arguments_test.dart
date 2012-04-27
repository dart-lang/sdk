// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo(a, [b]) {
}

class A {
  A(a, [b]);
}

class B {
  B()
    : super(b: 1) /// 01: runtime error
  ;
}

main() {
  new B(); /// 01: continued
  foo(b: 1); /// 02: runtime error
}
