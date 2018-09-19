// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

topFn<T extends num>(T x) {
  print(T);
}

class C<T> {
  instanceFn<S extends T>(S x) {
    print(S);
  }
}

class D<T> extends C<T> {
  void foo() {
    void Function(int) k = instanceFn; //# 03: compile-time error
  }
}

void main() {
  localFn<T extends num>(T x) {
    print(T);
  }

  void Function(String) k0 = localFn; //# 01: compile-time error
  void Function(String) k1 = topFn; //# 02: compile-time error
}
