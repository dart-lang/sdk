// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous subtyping for the `out` variance modifier.

// SharedOptions=--enable-experiment=variance

class Covariant<out T> {}

class Upper {}
class Middle extends Upper {}
class Lower {}

class A {
  Covariant<Middle> method1() {
    return Covariant<Middle>();
  }

  void method2(Covariant<Middle> x) {}
}

class B extends A {
  @override
  Covariant<Upper> method1() {
  //               ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
  // [cfe] The return type of the method 'B.method1' is 'Covariant<Upper>', which does not match the return type, 'Covariant<Middle>', of the overridden method, 'A.method1'.
    return new Covariant<Upper>();
  }

  @override
  void method2(Covariant<Lower> x) {}
  //   ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
  //                            ^
  // [cfe] The parameter 'x' of the method 'B.method2' has type 'Covariant<Lower>', which does not match the corresponding type, 'Covariant<Middle>', in the overridden method, 'A.method2'.
}

class C<out T extends Covariant<Middle>> {}

class D {
  C<Covariant<Upper>> method1() {
  //^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  //                         ^
  // [cfe] Type argument 'Covariant<Upper>' doesn't conform to the bound 'Covariant<Middle>' of the type variable 'T' on 'C' in the return type.
    return C<Covariant<Upper>>();
    //     ^
    // [cfe] Type argument 'Covariant<Upper>' doesn't conform to the bound 'Covariant<Middle>' of the type variable 'T' on 'C'.
    //       ^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  }
}

void testCall(Iterable<Covariant<Lower>> x) {}

main() {
  C<Covariant<Upper>> c = new C<Covariant<Upper>>();
  //^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  //                  ^
  // [cfe] Type argument 'Covariant<Upper>' doesn't conform to the bound 'Covariant<Middle>' of the type variable 'T' on 'C'.
  //                          ^
  // [cfe] Type argument 'Covariant<Upper>' doesn't conform to the bound 'Covariant<Middle>' of the type variable 'T' on 'C'.
  //                            ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

  Iterable<Covariant<Lower>> iterableLower = [new Covariant<Lower>()];
  List<Covariant<Middle>> listMiddle = [new Covariant<Middle>()];
  iterableLower = listMiddle;
  //              ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'List<Covariant<Middle>>' can't be assigned to a variable of type 'Iterable<Covariant<Lower>>'.

  testCall(listMiddle);
  //       ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'List<Covariant<Middle>>' can't be assigned to the parameter type 'Iterable<Covariant<Lower>>'.
}
