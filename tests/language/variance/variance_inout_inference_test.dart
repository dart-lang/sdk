// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests local inference for the `inout` variance modifier.

// SharedOptions=--enable-experiment=variance

class Covariant<out T> {}
class Contravariant<in T> {}
class Invariant<inout T> {}

class Exactly<inout T> {}

class Upper {}
class Middle extends Upper {}
class Lower extends Middle {}

Exactly<T> inferInvInv<T>(Invariant<T> x, Invariant<T> y) => new Exactly<T>();
Exactly<T> inferInvCov<T>(Invariant<T> x, Covariant<T> y) => new Exactly<T>();
Exactly<T> inferInvContra<T>(Invariant<T> x, Contravariant<T> y) => new Exactly<T>();

main() {
  Exactly<Middle> middle;

  // Middle <: T <: Middle
  // Choose Middle
  var inferredMiddle = inferInvInv(Invariant<Middle>(), Invariant<Middle>());
  middle = inferredMiddle;

  // Lower <: T
  // Middle <: T <: Middle
  // Choose Middle since this merges to Middle <: T <: Middle
  var inferredMiddle2 = inferInvCov(Invariant<Middle>(), Covariant<Lower>());
  middle = inferredMiddle2;

  // Middle <: T
  // Middle <: T <: Middle
  // Choose Middle since this merges to Middle <: T <: Middle
  var inferredMiddle3 = inferInvCov(Invariant<Middle>(), Covariant<Middle>());
  middle = inferredMiddle3;

  // T <: Upper
  // Middle <: T <: Middle
  // Choose Middle since this merges to Middle <: T <: Middle
  var inferredMiddle4 = inferInvContra(Invariant<Middle>(), Contravariant<Upper>());
  middle = inferredMiddle4;

  // T <: Middle
  // Middle <: T <: Middle
  // Choose Middle since this merges to Middle <: T <: Middle
  var inferredMiddle5 = inferInvContra(Invariant<Middle>(), Contravariant<Middle>());
  middle = inferredMiddle5;
}
