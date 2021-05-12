// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// @dart=2.9
abstract class A1 {
  void extendedClassMember() {}
  void extendedInterfaceMember();
}

abstract class A2 {
  void mixedInClassMember() {}
  void mixedInInterfaceMember();
}

abstract class A3 extends A1 with A2 {
  void declaredClassMember() {}
  void declaredInterfaceMember();
}

abstract class A4 = A1 with A2;

abstract class A5 implements A1 {}

class A6 extends A1 implements A1 {}

abstract class B1 {
  void twiceInterfaceMember() {}
  void extendedAndImplementedMember() {}
}

abstract class B2 {
  void twiceInterfaceMember() {}
}

abstract class B3 {
  void extendedAndImplementedMember() {}
}

abstract class B4 extends B3 implements B1, B2 {}

class B5 extends B4 {}

class B6 extends B3 implements B1, B2 {}

abstract class C1 {
  void mixedInAndImplementedClassMember() {}
  void mixedInAndImplementedInterfaceMember();
}

class C2 {
  void mixedInAndImplementedClassMember() {}
  void mixedInAndImplementedInterfaceMember() {}
}

abstract class C3 with C1 implements C2 {}

class C4 extends C3 {}

class C5 with C1 implements C2 {}

main() {}
