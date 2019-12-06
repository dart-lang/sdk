// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests local inference for the `in` variance modifier.

// SharedOptions=--enable-experiment=variance

class Covariant<out T> {}
class Contravariant<in T> {}

class Exactly<inout T> {}

class Upper {}
class Middle extends Upper {}
class Lower extends Middle {}

class ContraBound<in T> {
  ContraBound(T x, void Function(T) y) {}
}

Exactly<T> inferCovContra<T>(Covariant<T> x, Contravariant<T> y) => new Exactly<T>();
Exactly<T> inferContraContra<T>(Contravariant<T> x, Contravariant<T> y) => new Exactly<T>();
Exactly<T> inferContraBound<T>(ContraBound<T> x) => new Exactly<T>();

main() {
  Exactly<Upper> upper;
  Exactly<Middle> middle;
  Exactly<Lower> lower;

  // Lower <: T
  // T <: Lower
  // Choose Lower for Lower <: T <: Lower
  var inferredLower = inferCovContra(Covariant<Lower>(), Contravariant<Lower>());
  lower = inferredLower;

  // Lower <: T
  // T <: Middle
  // Choose Lower for Lower <: T <: Middle
  var inferredLower2 = inferCovContra(Covariant<Lower>(), Contravariant<Middle>());
  lower = inferredLower2;

  // Lower <: T
  // T <: Upper
  // Choose Lower for Lower <: T <: Upper
  var inferredLower3 = inferCovContra(Covariant<Lower>(), Contravariant<Upper>());
  lower = inferredLower3;

  // T <: Upper
  // T <: Middle
  // Choose Middle since it is the greatest lower bound of Upper and Middle.
  var inferredMiddle = inferContraContra(Contravariant<Upper>(), Contravariant<Middle>());
  middle = inferredMiddle;

  // T <: Upper
  // T <: Lower
  // Choose Lower since it is the greatest lower bound of Upper and Lower.
  var inferredLower4 = inferContraContra(Contravariant<Lower>(), Contravariant<Upper>());
  lower = inferredLower4;

  // T <: Middle
  // T <: Lower
  // Choose Lower since it is the greatest lower bound of Middle and Lower.
  var inferredLower5 = inferContraContra(Contravariant<Lower>(), Contravariant<Middle>());
  lower = inferredLower5;

  // Lower <: T <: Upper
  // Choose Upper.
  var inferredContraUpper = inferContraBound(ContraBound(Lower(), (Upper x) {}));
  upper = inferredContraUpper;

  // Lower <: T <: Middle
  // Choose Middle.
  var inferredContraMiddle = inferContraBound(ContraBound(Lower(), (Middle x) {}));
  middle = inferredContraMiddle;
}
