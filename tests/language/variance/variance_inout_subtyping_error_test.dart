// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous subtyping for the `inout` variance modifier.

// SharedOptions=--enable-experiment=variance

class Invariant<inout T> {}

class Upper {}
class Middle extends Upper {}
class Lower extends Middle {}

class A {
  Invariant<Middle> method1() {
    return Invariant<Middle>();
  }

  void method2(Invariant<Middle> x) {}
}

class B extends A {
  @override
  Invariant<Upper> method1() {
  //               ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
  // [cfe] The return type of the method 'B.method1' is 'Invariant<Upper>', which does not match the return type, 'Invariant<Middle>', of the overridden method, 'A.method1'.
    return new Invariant<Upper>();
  }

  @override
  void method2(Invariant<Lower> x) {}
  //   ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
  //                            ^
  // [cfe] The parameter 'x' of the method 'B.method2' has type 'Invariant<Lower>', which does not match the corresponding type, 'Invariant<Middle>', in the overridden method, 'A.method2'.
}

class C extends A {
  @override
  Invariant<Lower> method1() {
  //               ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
  // [cfe] The return type of the method 'C.method1' is 'Invariant<Lower>', which does not match the return type, 'Invariant<Middle>', of the overridden method, 'A.method1'.
    return new Invariant<Lower>();
  }

  @override
  void method2(Invariant<Upper> x) {}
  //   ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_OVERRIDE
  //                            ^
  // [cfe] The parameter 'x' of the method 'C.method2' has type 'Invariant<Upper>', which does not match the corresponding type, 'Invariant<Middle>', in the overridden method, 'A.method2'.
}

class D<out T extends Invariant<Middle>> {}

class E {
  D<Invariant<Upper>> method1() {
  //^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  //                         ^
  // [cfe] Type argument 'Invariant<Upper>' doesn't conform to the bound 'Invariant<Middle>' of the type variable 'T' on 'D' in the return type.
    return D<Invariant<Upper>>();
    //     ^
    // [cfe] Type argument 'Invariant<Upper>' doesn't conform to the bound 'Invariant<Middle>' of the type variable 'T' on 'D'.
    //       ^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  }

  D<Invariant<Lower>> method2() {
  //^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  //                         ^
  // [cfe] Type argument 'Invariant<Lower>' doesn't conform to the bound 'Invariant<Middle>' of the type variable 'T' on 'D' in the return type.
    return D<Invariant<Lower>>();
    //     ^
    // [cfe] Type argument 'Invariant<Lower>' doesn't conform to the bound 'Invariant<Middle>' of the type variable 'T' on 'D'.
    //       ^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  }
}

void testCall<T>(Iterable<Invariant<T>> x) {}

main() {
  D<Invariant<Upper>> dUpper = new D<Invariant<Upper>>();
  //^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  //                  ^
  // [cfe] Type argument 'Invariant<Upper>' doesn't conform to the bound 'Invariant<Middle>' of the type variable 'T' on 'D'.
  //                               ^
  // [cfe] Type argument 'Invariant<Upper>' doesn't conform to the bound 'Invariant<Middle>' of the type variable 'T' on 'D'.
  //                                 ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  D<Invariant<Lower>> dLower = new D<Invariant<Lower>>();
  //^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
  //                  ^
  // [cfe] Type argument 'Invariant<Lower>' doesn't conform to the bound 'Invariant<Middle>' of the type variable 'T' on 'D'.
  //                               ^
  // [cfe] Type argument 'Invariant<Lower>' doesn't conform to the bound 'Invariant<Middle>' of the type variable 'T' on 'D'.
  //                                 ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS

  Iterable<Invariant<Lower>> iterableLower = [new Invariant<Lower>()];
  List<Invariant<Middle>> listMiddle = [new Invariant<Middle>()];
  iterableLower = listMiddle;
  //              ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'List<Invariant<Middle>>' can't be assigned to a variable of type 'Iterable<Invariant<Lower>>'.

  Iterable<Invariant<Middle>> iterableMiddle = [new Invariant<Middle>()];
  List<Invariant<Lower>> listLower = [new Invariant<Lower>()];
  iterableMiddle = listLower;
  //               ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'List<Invariant<Lower>>' can't be assigned to a variable of type 'Iterable<Invariant<Middle>>'.

  testCall<Lower>(listMiddle);
  //              ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'List<Invariant<Middle>>' can't be assigned to the parameter type 'Iterable<Invariant<Lower>>'.

  testCall<Middle>(listLower);
  //               ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'List<Invariant<Lower>>' can't be assigned to the parameter type 'Iterable<Invariant<Middle>>'.
}
