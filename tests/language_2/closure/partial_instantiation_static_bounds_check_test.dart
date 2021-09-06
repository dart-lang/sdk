// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

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
    void Function(int) k = instanceFn;
    //                     ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
    // [cfe] Inferred type argument 'int' doesn't conform to the bound 'T' of the type variable 'S' on 'dynamic Function<S extends T>(S)'.
  }
}

void main() {
  localFn<T extends num>(T x) {
    print(T);
  }

  void Function(String) k0 = localFn;
  //                         ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
  // [cfe] Inferred type argument 'String' doesn't conform to the bound 'num' of the type variable 'T' on 'Null Function<T extends num>(T)'.
  void Function(String) k1 = topFn;
  //                         ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
  // [cfe] Inferred type argument 'String' doesn't conform to the bound 'num' of the type variable 'T' on 'dynamic Function<T extends num>(T)'.
}
