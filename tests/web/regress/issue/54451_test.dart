// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the bounds for structural parameters of a Function type are
// visited and any type variables RTI might need are registered.

class A<T> {
  void foo1() {
    void bar1<Z extends void Function<Y extends T>()>() {}
    print(bar1.runtimeType); // Crashes compiler if A.T is not accessible.
  }
}

extension<T> on T {
  void foo2() {
    void bar2<Z extends void Function<Y extends T>()>() {}
    print(bar2.runtimeType); // Crashes compiler if T is not accessible.
  }
}

void main() {
  A<int>().foo1();
  1.foo2();
}
