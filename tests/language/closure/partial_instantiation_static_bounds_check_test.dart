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
    void Function(int) k = instanceFn;
    //                     ^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    // [cfe] Inferred type argument 'int' doesn't conform to the bound 'T' of the type variable 'S' on 'dynamic Function<S extends T>(S)'.
  }
}

void main() {
  localFn<T extends num>(T x) {
    print(T);
  }

  void Function(String) k0 = localFn;
  //                         ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Null Function(num)' can't be assigned to a variable of type 'void Function(String)'.
  void Function(String) k1 = topFn;
  //                         ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'dynamic Function(num)' can't be assigned to a variable of type 'void Function(String)'.
}
