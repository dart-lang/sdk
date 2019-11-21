// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests downwards inference for explicit variance modifiers.

// SharedOptions=--enable-experiment=variance

class A<out T> {
  final T _x;
  A(T x):_x = x;
  T get x => _x;
  void set x(Object value) {}
}

class B<in T> {
  B(List<T> x);
  void set x(T val) {}
}

class C<out T, S> {
  final T _x;
  C(T x, S y):_x = x;
  T get x => _x;
  void set x(Object value) {}
  void set y(S _value) {}
}

class D<in T> {
  D(T x, void Function(T) y) {}
  void set x(T val) {}
}

main() {
  // int <: T <: Object
  // Choose int
  A<Object> a = new A(3)..x+=1;

  // int <: T
  // num <: T
  // Choose num
  B<int> b = new B(<num>[])..x=2.2;

  // int <: T <: Object
  // Choose int
  // int <: S <: Object
  // Choose Object
  C<Object, Object> c = new C(3, 3)..x+=1..y="hello";

  // int <: T <: num
  // Choose num due to contravariant heuristic.
  D<int> d = new D(3, (num x) {})..x=2.2;
}
