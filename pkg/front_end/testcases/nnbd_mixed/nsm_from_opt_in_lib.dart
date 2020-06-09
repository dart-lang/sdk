// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int method(int? i) => i ?? 0;
  T genericMethod1<T>(T t) => t;
  T genericMethod2<T extends Object?>(T t) => t;
  T genericMethod3<T extends Object>(T t) => t;
}

abstract class B1 extends A implements C1 {
  @override
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

abstract class C1 {
  int method(int? i, {optional});
  T genericMethod1<T>(T t);
  T genericMethod2<T extends Object?>(T t);
  T genericMethod3<T extends Object>(T t);
}
