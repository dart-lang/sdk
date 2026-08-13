// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests local inference errors for the `out` variance modifier.

// SharedOptions=--enable-experiment=variance

class Covariant<out T> {}

class Exactly<inout T> {}

class Upper {}
class Middle extends Upper {}
class Lower extends Middle {}

class CovBound<out T> {
  CovBound(T x, void Function(T) y) {}
}

Exactly<T> inferCovCov<T>(Covariant<T> x, Covariant<T> y) => new Exactly<T>();
Exactly<T> inferCovBound<T>(CovBound<T> x) => new Exactly<T>();

main() {
  Exactly<Upper> upper;
  Exactly<Middle> middle;
  Exactly<Lower> lower;

  // Lower <: T <: Middle.
  // We choose Middle.
  var inferredMiddle = inferCovCov(Covariant<Lower>(), Covariant<Middle>());
  lower = inferredMiddle;
  //      ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<Middle>' can't be assigned to a variable of type 'Exactly<Lower>'.

  // Lower <: T <: Upper.
  // We choose Upper.
  var inferredUpper = inferCovCov(Covariant<Lower>(), Covariant<Upper>());
  lower = inferredUpper;
  //      ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<Upper>' can't be assigned to a variable of type 'Exactly<Lower>'.

  // Inference for Covbound(...) produces Lower <: T <: Upper.
  // Since T is covariant, we choose Lower as the solution.
  var inferredCovLower = inferCovBound(CovBound(Lower(), (Upper x) {}));
  upper = inferredCovLower;
  //      ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<Lower>' can't be assigned to a variable of type 'Exactly<Upper>'.

  // Inference for Covbound(...) produces Lower <: T <: Middle.
  // Since T is covariant, we choose Lower as the solution.
  var inferredCovLower2 = inferCovBound(CovBound(Lower(), (Middle x) {}));
  middle = inferredCovLower2;
  //       ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<Lower>' can't be assigned to a variable of type 'Exactly<Middle>'.
}
