// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

extension type E1<T>(T foo) {}
extension type E2(Object? foo) {}
extension type E3(E1<String?> foo) {}
extension type E4(E1<int> foo) {}
extension type E5(E2 foo) {}

// Test that the extension types with not non-nullable representation type are not non-nullable themselves.
testNotNonNullable(E1<num?> e1numNullableNNN, E1<double> e1doubleNNN, E2 e2NNN, E3 e3NNN, E4 e4NNN, E5 e5NNN) {
  Object x1numNullable = e1numNullableNNN; // Error.
  Object x1double = e1doubleNNN; // Ok.
  Object x2 = e2NNN; // Error.
  Object x3 = e3NNN; // Error.
  Object x4 = e4NNN; // Ok.
  Object x5 = e5NNN; // Error.
}

// Test that the extension types with not non-nullable representation type are not nullable either
testNotNullable(
  E1<num?> e1numNullableNN, E1<double> e1doubleNN, E2 e2NN, E3 e3NN, E4 e4NN, E5 e5NN,
  E1<num?>? e1numNullableNNNullable, E1<double>? e1doubleNNNullable, E2? e2NNNullable, E3? e3NNNullable, E4? e4NNNullable, E5? e5NNNullable,
) {
  e1numNullableNN = null; // Error.
  e1doubleNN = null; // Error.
  e2NN = null; // Error.
  e3NN = null; // Error.
  e4NN = null; // Error.
  e5NN = null; // Error.

  e1numNullableNNNullable = null; // Ok.
  e1doubleNNNullable = null; // Ok.
  e2NNNullable = null; // Ok.
  e3NNNullable = null; // Ok.
  e4NNNullable = null; // Ok.
  e5NNNullable = null; // Ok.
}

// Since the extension types with not non-nullable representation type aren't nullable,
// not initializing fields of that type or not providing default type for parameters
// of such types is an error.
class A {
  E1<num?> e1numNullableA; // Error.
  E1<double> e1doubleA; // Error.
  E2 e2A; // Error.
  E3 e3A; // Error.
  E4 e4A; // Error.
  E5 e5A; // Error.

  E1<num?>? e1numNullableANullable; // Ok.
  E1<double>? e1doubleANullable; // Ok.
  E2? e2ANullable; // Ok.
  E3? e3ANullable; // Ok.
  E4? e4ANullable; // Ok.
  E5? e5ANullable; // Ok.

}

testOptionalPositional([
    E1<num?> e1numNullableOP, // Error.
    E1<double> e1doubleOP, // Error.
    E2 e2OP, // Error.
    E3 e3OP, // Error.
    E4 e4OP, // Error.
    E5 e5OP, // Error.

    E1<num?>? e1numNullableOPNullable, // Ok.
    E1<double>? e1doubleOPNullable, // Ok.
    E2? e2OPNullable, // Ok.
    E3? e3OPNullable, // Ok.
    E4? e4OPNullable, // Ok.
    E5? e5OPNullable // Ok.
]) {}

testNamedNotRequired({
    E1<num?> e1numNullableNNR, // Error.
    E1<double> e1doubleNNR, // Error.
    E2 e2NNR, // Error.
    E3 e3NNR, // Error.
    E4 e4NNR, // Error.
    E5 e5NNR, // Error.

    E1<num?>? e1numNullableNNRNullable, // Ok.
    E1<double>? e1doubleNNRNullable, // Ok.
    E2? e2NNRNullable, // Ok.
    E3? e3NNRNullable, // Ok.
    E4? e4NNRNullable, // Ok.
    E5? e5NNRNullable // Ok.

}) {}
