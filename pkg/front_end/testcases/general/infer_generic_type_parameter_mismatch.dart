// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef F<T> = T Function(T, T);

test1() {
  F<int> d = (int a, int b) => a;
  d = <S>(S a, S b) => a;
}

test2() {
  F<int> d = (int a, int b) => a;
  var f = <S>(S a, S b) => a;
  d = f;
}

test3a() {
  F<int> d = (int a, int b) => a;
  d = <S>(a, S b) => a;
}

test3b() {
  F<int> d = (int a, int b) => a;
  d = <S>(a, S b) => b;
}

test4() {
  F<int> d = (int a, int b) => a;
  d = <S>(a, b) => a;
}

test5() {
  F<int> d = (int a, int b) => a;
  d = (a, b, c) => a;
}

test6() {
  F<int> d = (int a, int b) => a;
  d = (a) => a;
}

test7() {
  F<int> d = (int a, int b) => a;
  d = <S>(a, b, c) => a;
}

test8() {
  F<int> d = (int a, int b) => a;
  d = <S>(a) => a;
}

main() {}
