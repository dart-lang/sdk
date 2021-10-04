// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

method<T extends Class, S extends int>(Class c, int i, T t, S s) {
  c<int>; // ok
  i<int>; // ok
  t<int>; // ok
  s<int>; // ok
}

test<T extends Class?, S extends int>(
    Class? c1,
    GetterCall c2,
    int? i,
    T t1,
    T? t2,
    S? s,
    void Function<T>()? f1,
    Never n,
    dynamic d,
    String a,
    double b,
    bool c,
    FutureOr<Class> f2,
    Function f3) {
  c1<int>; // error
  c2<int>; // error
  i<int>; // error
  t1<int>; // error
  t2<int>; // error
  s<int>; // error
  f1<int>; // error
  n<int>; // error
  d<int>; // error
  a<int>; // error
  b<int>; // error
  c<int>; // error
  f2<int>; // error
  f3<int>; // error
}

class Class {
  call<T>() {}
}

class GetterCall {
  void Function<T>() get call => <T>() {};
}

extension Extension on int {
  call<T>() {}
}

extension ExtensionGetter on double {
  void Function<T>() get call => <T>() {};
}

extension ExtensionSetter on bool {
  set call(void Function<T>() value) {}
}

extension Ambiguous1 on String {
  call<T>() {}
}

extension Ambiguous2 on String {
  call<T>() {}
}

main() {
  method(Class(), 0, Class(), 0);
}
