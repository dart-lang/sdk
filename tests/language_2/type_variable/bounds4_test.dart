// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test instantiation of object with malbounded types.

class A<
    T
          extends num
    > {}

class B<T> implements A<T> {}
//    ^
// [cfe] Type argument 'T' doesn't conform to the bound 'num' of the type variable 'T' on 'A' in the supertype 'A' of class 'B'.
//                      ^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

class C<
    T
          extends num
    > implements B<T> {}

class Class<T> {
  newA() {
    new A<T>();
    //  ^
    // [cfe] Type argument 'T' doesn't conform to the bound 'num' of the type variable 'T' on 'A'.
    //    ^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  }
  newB() {
    new B<T>();
  }
  newC() {
    new C<T>();
    //  ^
    // [cfe] Type argument 'T' doesn't conform to the bound 'num' of the type variable 'T' on 'C'.
    //    ^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  }
}

void test(f()) {
  var v = f();
}

void main() {
  test(() => new A<int>());
  // TODO(eernst): Should it be a compile-time error to create an instance
  // of this class in #01?
  test(() => new B<int>());
  test(() => new C<int>());

  test(() => new A<String>());
  //             ^
  // [cfe] Type argument 'String' doesn't conform to the bound 'num' of the type variable 'T' on 'A'.
  //               ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  test(() => new B<String>());
  test(() => new C<String>());
  //             ^
  // [cfe] Type argument 'String' doesn't conform to the bound 'num' of the type variable 'T' on 'C'.
  //               ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

  dynamic c = new Class<int>();
  test(() => c.newA());
  test(() => c.newB());
  test(() => c.newC());

  c = new Class<String>();
  test(() => c.newA());
  test(() => c.newB());
  test(() => c.newC());
}
