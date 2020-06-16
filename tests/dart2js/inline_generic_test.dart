// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test that inlining of constructors with `double` as type argument registers
/// that double is need for checking passed values.

class C<T> implements D<T> {
  T a;

  C.gen(this.a);
}

class D<T> {
  factory D.fact(T a) => new C<T>.gen(a);
}

main() {
  new C<double>.gen(0.5); //# 01: ok
  new D<double>.fact(0.5); //# 02: ok
  <double>[].add(0.5); //# 03: ok
  <int, double>{}[0] = 0.5; //# 04: ok
}
