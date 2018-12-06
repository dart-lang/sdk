// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N super_goes_last`

class A {
  int a;
  A(this.a);
}

class B extends A {
  int _b;
  B(int a)
      : _b = a + 1,
        super(a); // OK
}

class C extends A {
  int _c;
  C(int a)
      : super(a), // LINT [9:8]
        _c = a + 1;
}
