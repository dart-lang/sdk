// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void f0(this.x) {} // //# 0: compile-time error

void f1(int g(this.x)) {} // //# 1: compile-time error

void f2(int g(int this.x)) {} // //# 2: compile-time error

class C {
  C();
  var x;
  void f3(int g(this.x)) {} // //# 3: compile-time error
  C.f4(int g(this.x)); // //# 4: compile-time error
}

main() {
  f0(null); // //# 0: continued
  f1(null); // //# 1: continued
  f2(null); // //# 2: continued
  C c = new C();
  c.f3(null); // //# 3: continued
  new C.f4(null); // //# 4: continued
}
