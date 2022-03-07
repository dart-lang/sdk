// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A<T> {
  void _method1(int a, int b, T c, T d);
  void _method2({int a, int b, T c, T d});
  void _method3(int a, T b);
  void _method4({int a, T b});
}

abstract class B {
  void _method1(int x, covariant int y, int z, covariant int w);
  void _method2({int a, covariant int b, int c, covariant int d});
  void _method3(covariant int x, int y);
  void _method4({covariant int a, int b});
}

abstract class C1 implements A<int>, B {}

abstract class C2 implements B, A<int> {}

class C3 implements A<int>, B {
  @override
  noSuchMethod(Invocation invocation) => null;
}

class C4 implements B, A<int> {
  @override
  noSuchMethod(Invocation invocation) => null;
}
