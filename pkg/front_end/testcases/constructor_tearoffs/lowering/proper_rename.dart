// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B<T> {}

class C<X, Y> {}

class D<X extends num> {}

typedef F = A;

typedef G0 = B;
typedef G1 = B<int>;
typedef G2<T> = B<T>;
typedef G3<T extends num> = B<T>;

typedef H0 = C;
typedef H1 = C<int, String>;
typedef H2<T> = C<int, T>;
typedef H3<T, S> = C<T, S>;
typedef H4<T, S> = C<S, T>;
typedef H5<T extends num, S> = C<T, S>;
typedef H6<T, S extends num> = C<T, S>;

typedef I0 = D;
typedef I1 = D<num>;
typedef I2<T extends num> = D<T>;
typedef I3<T extends int> = D<T>;

main() {
  var f = F.new;

  var g0 = G0.new;
  var g1 = G1.new;
  var g2a = G2.new;
  var g2b = G2<int>.new;
  var g3a = G3.new;
  var g3b = G3<int>.new;

  var h0 = H0.new;
  var h1 = H1.new;
  var h2a = H2.new;
  var h2b = H2<int>.new;
  var h3a = H3.new;
  var h3b = H3<int, String>.new;
  var h4a = H4.new;
  var h4b = H4<int, String>.new;
  var h5a = H5.new;
  var h5b = H5<int, String>.new;
  var h6a = H6.new;
  var h6b = H6<String, int>.new;

  var i0 = I0.new;
  var i1 = I1.new;
  var i2a = I2.new;
  var i2b = I2<int>.new;
  var i3a = I3.new;
  var i3b = I3<int>.new;
}
