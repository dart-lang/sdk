// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous upper and lower bounds computation with respect to
// variance modifiers.

// SharedOptions=--enable-experiment=variance

class Covariant<out T> {}
class Contravariant<in T> {}
class Invariant<inout T> {}
class LegacyCovariant<T> {}

class Multi<out T, inout U, in V> {}

class Exactly<inout T> {}
Exactly<T> exactly<T>(T x) => new Exactly<T>();

class Upper {}
class Middle extends Upper {}
class Lower extends Middle {}

main() {
  bool condition = true;

  var contraLowerActual =
      exactly(condition ? Contravariant<Upper>() : Contravariant<Lower>());
  Exactly<Contravariant<Upper>> contraUpperExpected = contraLowerActual;
  //                                                  ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<Contravariant<Lower>>' can't be assigned to a variable of type 'Exactly<Contravariant<Upper>>'.

  var contraMiddleActual =
      exactly(condition ? Contravariant<Upper>() : Contravariant<Middle>());
  contraUpperExpected = contraMiddleActual;
  //                    ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<Contravariant<Middle>>' can't be assigned to a variable of type 'Exactly<Contravariant<Upper>>'.

  var covMiddleActual =
      exactly(condition ? Covariant<Middle>() : Covariant<Lower>());
  Exactly<Covariant<Lower>> covLowerExpected = covMiddleActual;
  //                                           ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<Covariant<Middle>>' can't be assigned to a variable of type 'Exactly<Covariant<Lower>>'.

  var covUpperActual =
      exactly(condition ? Covariant<Upper>() : Covariant<Lower>());
  covLowerExpected = covUpperActual;
  //                 ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<Covariant<Upper>>' can't be assigned to a variable of type 'Exactly<Covariant<Lower>>'.

  var invObjectActual =
      exactly(condition ? Invariant<Upper>() : Invariant<Middle>());
  Exactly<Invariant<Middle>> invMiddleExpected = invObjectActual;
  //                                             ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<Object>' can't be assigned to a variable of type 'Exactly<Invariant<Middle>>'.
  Exactly<Invariant<Upper>> invUpperExpected = invObjectActual;
  //                                           ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<Object>' can't be assigned to a variable of type 'Exactly<Invariant<Upper>>'.

  var legacyCovMiddleActual =
      exactly(condition ? LegacyCovariant<Middle>() : LegacyCovariant<Lower>());
  Exactly<LegacyCovariant<Lower>> legacyCovLowerExpected =
      legacyCovMiddleActual;
  //  ^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<LegacyCovariant<Middle>>' can't be assigned to a variable of type 'Exactly<LegacyCovariant<Lower>>'.

  var legacyCovUpperActual =
      exactly(condition ? LegacyCovariant<Upper>() : LegacyCovariant<Lower>());
  legacyCovLowerExpected = legacyCovUpperActual;
  //                       ^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<LegacyCovariant<Upper>>' can't be assigned to a variable of type 'Exactly<LegacyCovariant<Lower>>'.

  var multiActual = exactly(condition
      ? Multi<Middle, Middle, Middle>()
      : Multi<Lower, Middle, Lower>());
  Exactly<Multi<Lower, Middle, Lower>> multiExpected = multiActual;
  //                                                   ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<Multi<Middle, Middle, Lower>>' can't be assigned to a variable of type 'Exactly<Multi<Lower, Middle, Lower>>'.

  var multiActual2 = exactly(
      condition ? Multi<Middle, int, Middle>() : Multi<Lower, Middle, Lower>());
  Exactly<Multi<Middle, Object, Lower>> multiObjectExpected = multiActual2;
  //                                                          ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<Object>' can't be assigned to a variable of type 'Exactly<Multi<Middle, Object, Lower>>'.

  var multiActual3 = exactly(
      condition ? Multi<int, Middle, Middle>() : Multi<Lower, Middle, Lower>());
  Exactly<Object> multiObjectExpected2 = multiActual3;
  //                                     ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<Multi<Object, Middle, Lower>>' can't be assigned to a variable of type 'Exactly<Object>'.
}
