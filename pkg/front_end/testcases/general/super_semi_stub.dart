// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  void method(num a) {}
  void set setter(num a) {}
}

class Class extends Super {
  void method(covariant int a);
  void set setter(covariant int a);
}

class Subclass extends Class {
  void method(int a) {
    void Function(num) sup1 = super.method; // ok
    var sup2 = super.method;
    void Function(num) cls1 = Class().method; // error
    void Function(int) cls2 = Class().method; // ok
    var cls3 = Class().method;
  }

  void set setter(int a) {
    super.setter = 0; // ok
    super.setter = 0.5; // ok
    Class().setter = 0; // ok
    Class().setter = 0.5; // error
  }
}

test(Subclass sub) {
  sub.method(0); // ok
  sub.method(0.5); // error

  Class cls = sub;
  cls.method(0); // ok
  cls.method(0.5); // error

  Super sup = sub;
  sup.method(0); // ok
  sup.method(0.5); // ok
}

main() {}
