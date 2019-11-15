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

Exactly<T> inferCovCov<T>(Covariant<T> x, Covariant<T> y) => new Exactly<T>();

main() {
  Exactly<Lower> lower;

  var inferredMiddle = inferCovCov(Covariant<Lower>(), Covariant<Middle>());
  lower = inferredMiddle;
  //      ^^^^^^^^^^^^^^
  // [analyzer] STATIC_TYPE_WARNING.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<Middle>' can't be assigned to a variable of type 'Exactly<Lower>'.

  var inferredUpper = inferCovCov(Covariant<Lower>(), Covariant<Upper>());
  lower = inferredUpper;
  //      ^^^^^^^^^^^^^
  // [analyzer] STATIC_TYPE_WARNING.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<Upper>' can't be assigned to a variable of type 'Exactly<Lower>'.
}
