// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A<X extends num> {}

class B1 {
  void set bar(num? value) {}
  num get baz => 42;
  void hest(num? value) {}
}

class B2 extends B1 {
  num bar = 3.14; // Error in strong mode and Warning in weak mode.
  num? get baz => null; // Error in strong mode and Warning in weak mode.
  void hest(num value) {} // Error in strong mode and Warning in weak mode.
}

class C1 {
  factory C1() = C2<int?>; // Error in strong mode and Warning in weak mode.
}

class C2<X extends int> implements C1 {}

class D {
  D.foo(num x);
  factory D.bar(num? x) = D.foo; // Error in strong mode and Warning in weak mode.
}

main() {}
