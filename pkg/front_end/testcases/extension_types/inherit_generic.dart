// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type A<T>(Object it) {
  T method() => throw '';
  T get getter => throw '';
  void set setter(T value) {}
  T operator[] (T index) => throw '';
}

extension type B<S>(Object it) implements A<S> {
  S method2() => method();
  S get getter2 => getter;
  void set setter2(S value) {
    setter = value;
  }
  void operator[]= (S index, S value) {
    value = this[index];
  }
}

extension type C(Object i) implements A<int> {
  int method3() => method();
  int get getter3 => getter;
  void set setter3(int value) {
    setter = value;
  }
  void operator[]= (int index, int value) {
    value = this[index];
  }
}

test(A<bool> a, B<String> b, C c) {
  bool a1 = a.method();
  bool a2 = a.getter;
  a.setter = a1;
  bool a3 = a[a2];

  String b1 = b.method();
  String b2 = b.getter;
  b.setter = b1;
  String b3 = b[b2];
  String b4 = b.method2();
  String b5 = b.getter2;
  b.setter2 = b4;
  b[b5] = b1;

  int c1 = c.method();
  int c2 = c.getter;
  c.setter = c1;
  int c3 = c[c2];
  int c4 = c.method3();
  int c5 = c.getter3;
  c.setter3 = c4;
  c[c5] = c1;
}
