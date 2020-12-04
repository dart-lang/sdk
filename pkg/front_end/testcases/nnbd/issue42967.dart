// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Class A has no constructors.
class A {
  num fieldNonNullableOfA; // Error.
  late num fieldLateNonNullableOfA; // Ok.

  final dynamic fieldFinalDynamicOfA; // Error.
  late final dynamic fieldLateFinalDynamicOfA; // Ok.
}

// Class AbstractA has no constructors.
abstract class AbstractA {
  external num fieldExternalNonNullableOfAbstractA; // Ok.
  abstract num fieldAbstractNonNullableOfAbstractA; // Ok.

  external final dynamic fieldExternalFinalDynamicOfAbstractA; // Ok.
  abstract final dynamic fieldAbstractFinalDynamicOfAbstractA; // Ok.
}


// Class B has only factory constructors.
class B {
  num fieldNonNullableOfB; // Error.
  late num fieldLateNonNullableOfB; // Ok.

  final dynamic fieldFinalDynamicOfB; // Error.
  late final dynamic fieldLateFinalDynamicOfB; // Ok.

  factory B() => throw 42;
}

// Class AbstractB has only factory constructors.
abstract class AbstractB {
  external num fieldExternalNonNullableOfAbstractB; // Ok.
  abstract num fieldAbstractNonNullableOfAbstractB; // Ok.

  external final dynamic fieldExternalFinalDynamicOfAbstractB; // Ok.
  abstract final dynamic fieldAbstractFinalDynamicOfAbstractB; // Ok.
}

mixin M {
  num fieldNonNullableOfM; // Error.
  late num fieldLateNonNullableOfM; // Ok.
  external num fieldExternalNonNullableOfM; // Ok.
  abstract num fieldAbstractNonNullableOfM; // Ok.

  final dynamic fieldFinalDynamicOfM; // Error.
  late final dynamic fieldLateFinalDynamicOfM; // Ok.
  external final dynamic fieldExternalFinalDynamicOfM; // Ok.
  abstract final dynamic fieldAbstractFinalDynamicOfM; // Ok.
}

main() {}
