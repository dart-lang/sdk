// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  noSuchMethod(Invocation i) => "C";
  String foo();
}

mixin M {
  noSuchMethod(Invocation i) => "M";
  String foo();
}

class MA = Object with M;

void main() {
  C c = C();
  Function f1 = c.foo;
  print(f1()); // prints C

  MA ma = MA();
  Function f2 = ma.foo;
  print(f2()); // prints M
}
