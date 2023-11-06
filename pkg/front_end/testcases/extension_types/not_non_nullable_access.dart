// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

extension type ET1(int i) {
  ET1? operator +(ET1? i) => i;
  int operator -() => i;
  int operator [](int index) => i;
  void operator []=(int index, int value) {}
  void foo(int i) {}
  int get getter => i;
  void set setter(int value) {}
}

extension type ET2<T>(T t) {
  ET2<T>? operator +(ET2<T>? t) => t;
  T operator -() => t;
  T operator [](int index) => t;
  void operator []=(int index, T value) {}
  void foo(T t) {}
  T get getter => t;
  void set setter(T value) {}
}

method1(ET1 et) {
  et.foo(0); // Ok
  et.foo; // Ok
  et.setter = et.getter; // Ok
  et + et; // Ok
  -et; // Ok
  et[0]; // Ok
  et[0] = 0; // Ok
}

method2(ET1? et) {
  et.foo(0); // Error
  et.foo; // Error
  et.setter = // Error
  et.getter; // Error
  et + et; // Error
  -et; // Error
  et[0]; // Error
  et[0] = 0; // Error
}

method3<S>(S s, ET2<S> et) {
  et.foo(s); // Ok
  et.foo; // Ok
  et.setter = et.getter; // Ok
  et + et; // Ok
  -et; // Ok
  et[0]; // Ok
  et[0] = s; // Ok
}

method4<S>(S s, ET2<S>? et) {
  et.foo(s); // Error
  et.foo; // Error
  et.setter = // Error
  et.getter; // Error
  et + et; // Error
  -et; // Error
  et[0]; // Error
  et[0] = s; // Error
}

method5<S, U extends ET2<S>>(S s, U et) {
  et.foo(s); // Ok
  et.foo; // Ok
  et.setter = et.getter; // Ok
  et + et; // Ok
  -et; // Ok
  et[0]; // Ok
  et[0] = s; // Ok
}

method6<S, U extends ET2<S>>(S s, U? et) {
  et.foo(s); // Error
  et.foo; // Error
  et.setter = // Error
  et.getter; // Error
  et + et; // Error
  -et; // Error
  et[0]; // Error
  et[0] = s; // Error
}

method7<S, U extends ET2<S>, V extends U>(S s, V et) {
  et.foo(s); // Ok
  et.foo; // Ok
  et.setter = et.getter; // Ok
  et + et; // Ok
  -et; // Ok
  et[0]; // Ok
  et[0] = s; // Ok
}

method8<S, U extends ET2<S>, V extends U>(S s, V? et) {
  et.foo(s); // Error
  et.foo; // Error
  et.setter = // Error
  et.getter; // Error
  et + et; // Error
  -et; // Error
  et[0]; // Error
  et[0] = s; // Error
}

method9<S, U extends ET2<S>, V extends U?>(S s, V et) {
  et.foo(s); // Error
  et.foo; // Error
  et.setter = // Error
  et.getter; // Error
  et + et; // Error
  -et; // Error
  et[0]; // Error
  et[0] = s; // Error
}

method10<S, U extends ET2<S>?, V extends U>(S s, V et) {
  et.foo(s); // Error
  et.foo; // Error
  et.setter = // Error
  et.getter; // Error
  et + et; // Error
  -et; // Error
  et[0]; // Error
  et[0] = s; // Error
}
