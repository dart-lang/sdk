// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int field;

  A(this.field);
}

class B implements A {
  set field = 0;
  get field => 0;
}

class C implements A {
  set field() {}
  get field() => 0;
}

class D implements A {
  set field(a, b) {}
  get field(a, b) => 0;
}

class E implements A {
  set field([a]) {}
  get field([a]) => 0;
}

class F implements A {
  set field({a}) {}
  get field({a}) => 0;
}

class G implements A {
  set field {}
  get field(a) => 0;
}
