// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests upper and lower bounds computation with respect to variance modifiers.

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
  Exactly<Contravariant<Lower>> contraLowerExpected = contraLowerActual;

  var contraMiddleActual =
      exactly(condition ? Contravariant<Upper>() : Contravariant<Middle>());
  Exactly<Contravariant<Middle>> contraMiddleExpected = contraMiddleActual;

  var covMiddleActual =
      exactly(condition ? Covariant<Middle>() : Covariant<Lower>());
  Exactly<Covariant<Middle>> covMiddleExpected = covMiddleActual;

  var covUpperActual =
      exactly(condition ? Covariant<Upper>() : Covariant<Lower>());
  Exactly<Covariant<Upper>> covUpperExpected = covUpperActual;

  var invMiddleActual =
      exactly(condition ? Invariant<Middle>() : Invariant<Middle>());
  Exactly<Invariant<Middle>> invMiddleExpected = invMiddleActual;

  var invObjectActual =
      exactly(condition ? Invariant<Upper>() : Invariant<Middle>());
  Exactly<Object> invObjectExpected = invObjectActual;

  var legacyCovMiddleActual =
      exactly(condition ? LegacyCovariant<Middle>() : LegacyCovariant<Lower>());
  Exactly<LegacyCovariant<Middle>> legacyCovMiddleExpected =
      legacyCovMiddleActual;

  var legacyCovUpperActual =
      exactly(condition ? LegacyCovariant<Upper>() : LegacyCovariant<Lower>());
  Exactly<LegacyCovariant<Upper>> legacyCovUpperExpected = legacyCovUpperActual;

  var multiActual = exactly(condition
      ? Multi<Middle, Middle, Middle>()
      : Multi<Lower, Middle, Lower>());
  Exactly<Multi<Middle, Middle, Lower>> multiExpected = multiActual;

  var multiActual2 = exactly(
      condition ? Multi<Middle, int, Middle>() : Multi<Lower, Middle, Lower>());
  Exactly<Object> multiObjectExpected = multiActual2;

  var multiActual3 = exactly(
      condition ? Multi<int, Middle, Middle>() : Multi<Lower, Middle, Lower>());
  Exactly<Multi<Object, Middle, Lower>> multiObjectExpected2 = multiActual3;
}
