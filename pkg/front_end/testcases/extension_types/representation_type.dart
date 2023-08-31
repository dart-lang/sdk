// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type A(int it) {}
extension type Ba(A it) {}
extension type Bb(A? it) {}
extension type C<T>(T it) {}
extension type Da<T>(C<T> it) {}
extension type Db<T>(C<T?> it) {}
extension type Dc<T>(C<T>? it) {}
extension type E(int? it) {}
extension type Fa(E it) {}
extension type Fb(E? it) {}
extension type G<T>(T? it) {}
extension type Ha<T>(G<T> it) {}
extension type Hb<T>(G<T?> it) {}
extension type Hc<T>(G<T>? it) {}
extension type I<T extends Object>(T it) {}
extension type Ja<T extends Object>(I<T> it) {}
extension type Jc<T extends Object>(I<T>? it) {}
extension type K<T extends Object>(T? it) {}
extension type La<T extends Object>(K<T> it) {}
extension type Lc<T extends Object>(K<T>? it) {}

testA(Never n) {
  A a1 = n;
  A? a2 = n;
}

testBa(Never n) {
  Ba ba1 = n;
  Ba? ba2 = n;
  Bb bb3 = n;
  Bb? bb4 = n;
}

testC<S, U extends Object>(Never n) {
  C c1 = n;
  C? c2 = n;
  C<int> c3 = n;
  C<int?> c4 = n;
  C<int>? c5 = n;
  C<int?>? c6 = n;
  C<S> c7 = n;
  C<S>? c8 = n;
  C<S?> c9 = n;
  C<S?>? c10 = n;
  C<U> c11 = n;
  C<U>? c12 = n;
  C<U?> c13 = n;
  C<U?>? c14 = n;
}

testDa<S, U extends Object>(Never n) {
  Da da1 = n;
  Da? da2 = n;
  Da<int> da3 = n;
  Da<int?> da4 = n;
  Da<int>? da5 = n;
  Da<int?>? da6 = n;
  Da<S> da7 = n;
  Da<S>? da8 = n;
  Da<S?> da9 = n;
  Da<S?>? da10 = n;
  Da<U> da11 = n;
  Da<U>? da12 = n;
  Da<U?> da13 = n;
  Da<U?>? da14 = n;
}

testDb<S, U extends Object>(Never n) {
  Db db1 = n;
  Db? db2 = n;
  Db<int> db3 = n;
  Db<int?> db4 = n;
  Db<int>? db5 = n;
  Db<int?>? db6 = n;
  Db<S> db7 = n;
  Db<S>? db8 = n;
  Db<S?> db9 = n;
  Db<S?>? db10 = n;
  Db<U> db11 = n;
  Db<U>? db12 = n;
  Db<U?> db13 = n;
  Db<U?>? db14 = n;
}

testDc<S, U extends Object>(Never n) {
  Dc dc1 = n;
  Dc? dc2 = n;
  Dc<int> dc3 = n;
  Dc<int?> dc4 = n;
  Dc<int>? dc5 = n;
  Dc<int?>? dc6 = n;
  Dc<S> dc7 = n;
  Dc<S>? dc8 = n;
  Dc<S?> dc9 = n;
  Dc<S?>? dc10 = n;
  Dc<U> dc11 = n;
  Dc<U>? dc12 = n;
  Dc<U?> dc13 = n;
  Dc<U?>? dc14 = n;
}

testE(Never n) {
  E e1 = n;
  E? e2 = n;
}

testF(Never n) {
  Fa fa1 = n;
  Fa? fa2 = n;
  Fb fb3 = n;
  Fb? fb4 = n;
}

testG<S, U extends Object>(Never n) {
  G g1 = n;
  G? g2 = n;
  G<int> g3 = n;
  G<int?> g4 = n;
  G<int>? g5 = n;
  G<int?>? g6 = n;
  G<S> g7 = n;
  G<S>? g8 = n;
  G<S?> g9 = n;
  G<S?>? g10 = n;
  G<U> g11 = n;
  G<U>? g12 = n;
  G<U?> g13 = n;
  G<U?>? g14 = n;
}

testHa<S, U extends Object>(Never n) {
  Ha ha1 = n;
  Ha? ha2 = n;
  Ha<int> ha3 = n;
  Ha<int?> ha4 = n;
  Ha<int>? ha5 = n;
  Ha<int?>? ha6 = n;
  Ha<S> ha7 = n;
  Ha<S>? ha8 = n;
  Ha<S?> ha9 = n;
  Ha<S?>? ha10 = n;
  Ha<U> ha11 = n;
  Ha<U>? ha12 = n;
  Ha<U?> ha13 = n;
  Ha<U?>? ha14 = n;
}

testHb<S, U extends Object>(Never n) {
  Hb hb1 = n;
  Hb? hb2 = n;
  Hb<int> hb3 = n;
  Hb<int?> hb4 = n;
  Hb<int>? hb5 = n;
  Hb<int?>? hb6 = n;
  Hb<S> hb7 = n;
  Hb<S>? hb8 = n;
  Hb<S?> hb9 = n;
  Hb<S?>? hb10 = n;
  Hb<U> hb11 = n;
  Hb<U>? hb12 = n;
  Hb<U?> hb13 = n;
  Hb<U?>? hb14 = n;
}

testHc<S, U extends Object>(Never n) {
  Hc hc1 = n;
  Hc? hc2 = n;
  Hc<int> hc3 = n;
  Hc<int?> hc4 = n;
  Hc<int>? hc5 = n;
  Hc<int?>? hc6 = n;
  Hc<S> hc7 = n;
  Hc<S>? hc8 = n;
  Hc<S?> hc9 = n;
  Hc<S?>? hc10 = n;
  Hc<U> hc11 = n;
  Hc<U>? hc12 = n;
  Hc<U?> hc13 = n;
  Hc<U?>? hc14 = n;
}

testI<U extends Object>(Never n) {
  I i1 = n;
  I? i2 = n;
  I<int> i3 = n;
  I<int>? i5 = n;
  I<U> i11 = n;
  I<U>? i12 = n;
}

testJa<U extends Object>(Never n) {
  Ja ja1 = n;
  Ja? ja2 = n;
  Ja<int> ja3 = n;
  Ja<int>? ja5 = n;
  Ja<U> ja11 = n;
  Ja<U>? ja12 = n;
}

testJc<U extends Object>(Never n) {
  Jc jc1 = n;
  Jc? jc2 = n;
  Jc<int> jc3 = n;
  Jc<int>? jc5 = n;
  Jc<U> jc11 = n;
  Jc<U>? jc12 = n;
}

testK<U extends Object>(Never n) {
  K k1 = n;
  K? k2 = n;
  K<int> k3 = n;
  K<int>? k5 = n;
  K<U> k11 = n;
  K<U>? k12 = n;
}

testLa<U extends Object>(Never n) {
  La la1 = n;
  La? la2 = n;
  La<int> la3 = n;
  La<int>? la5 = n;
  La<U> la11 = n;
  La<U>? la12 = n;
}

testLc<U extends Object>(Never n) {
  Lc lc1 = n;
  Lc? lc2 = n;
  Lc<int> lc3 = n;
  Lc<int>? lc5 = n;
  Lc<U> lc11 = n;
  Lc<U>? lc12 = n;
}