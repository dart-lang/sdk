// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous subtyping for the `in` variance modifier.

// SharedOptions=--enable-experiment=variance

class Contravariant<in T> {}

class Upper {}
class Middle extends Upper {}
class Lower extends Middle {}

class A {
  Contravariant<Middle> method1() {
    return new Contravariant<Middle>();
  }

  void method2(Contravariant<Middle> x) {}
}

class B extends A {
  @override
  Contravariant<Lower> method1() {
  //                   ^
  // [analyzer] unspecified
  // [cfe] The return type of the method 'B.method1' is 'Contravariant<Lower>', which does not match the return type, 'Contravariant<Middle>', of the overridden method, 'A.method1'.
    return new Contravariant<Lower>();
  }

  @override
  void method2(Contravariant<Upper> x) {}
  //                                ^
  // [analyzer] unspecified
  // [cfe] The parameter 'x' of the method 'B.method2' has type 'Contravariant<Upper>', which does not match the corresponding type, 'Contravariant<Middle>', in the overridden method, 'A.method2'.
}

class C<out T extends Contravariant<Middle>> {}

class D {
  C<Contravariant<Lower>> method1() {
  //                             ^
  // [analyzer] unspecified
  // [cfe] Type argument 'Contravariant<Lower>' doesn't conform to the bound 'Contravariant<Middle>' of the type variable 'T' on 'C' in the return type.
    return C<Contravariant<Lower>>();
    //     ^
    // [analyzer] unspecified
    // [cfe] Type argument 'Contravariant<Lower>' doesn't conform to the bound 'Contravariant<Middle>' of the type variable 'T' on 'C'.
  }
}

void testCall(Iterable<Contravariant<Middle>> x) {}

main() {
  C<Contravariant<Lower>> c = new C<Contravariant<Lower>>();
  //                      ^
  // [analyzer] unspecified
  // [cfe] Type argument 'Contravariant<Lower>' doesn't conform to the bound 'Contravariant<Middle>' of the type variable 'T' on 'C'.
  //                              ^
  // [analyzer] unspecified
  // [cfe] Type argument 'Contravariant<Lower>' doesn't conform to the bound 'Contravariant<Middle>' of the type variable 'T' on 'C'.

  Iterable<Contravariant<Middle>> iterableMiddle = [new Contravariant<Middle>()];
  List<Contravariant<Lower>> listLower = [new Contravariant<Lower>()];
  iterableMiddle = listLower;
  //               ^
  // [analyzer] unspecified
  // [cfe] A value of type 'List<Contravariant<Lower>>' can't be assigned to a variable of type 'Iterable<Contravariant<Middle>>'.

  testCall(listLower);
  //       ^
  // [analyzer] unspecified
  // [cfe] The argument type 'List<Contravariant<Lower>>' can't be assigned to the parameter type 'Iterable<Contravariant<Middle>>'.
}
