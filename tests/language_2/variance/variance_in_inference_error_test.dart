// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests local inference errors for the `in` variance modifier.

// SharedOptions=--enable-experiment=variance

class Covariant<out T> {}
class Contravariant<in T> {}

class Exactly<inout T> {}

class Upper {}
class Middle extends Upper {}
class Lower extends Middle {}

Exactly<T> inferCovContra<T>(Covariant<T> x, Contravariant<T> y) => new Exactly<T>();
Exactly<T> inferContraContra<T>(Contravariant<T> x, Contravariant<T> y) => new Exactly<T>();

main() {
  Exactly<Upper> upper;

  var inferredMiddle = inferContraContra(Contravariant<Upper>(), Contravariant<Middle>());
  upper = inferredMiddle;
  //      ^^^^^^^^^^^^^^
  // [analyzer] STATIC_TYPE_WARNING.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<Middle>' can't be assigned to a variable of type 'Exactly<Upper>'.

  var inferredLower = inferContraContra(Contravariant<Upper>(), Contravariant<Lower>());
  upper = inferredLower;
  //      ^^^^^^^^^^^^^
  // [analyzer] STATIC_TYPE_WARNING.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Exactly<Lower>' can't be assigned to a variable of type 'Exactly<Upper>'.

  // int <: T <: String is not a valid constraint.
  inferCovContra(Covariant<int>(), Contravariant<String>());
//^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
  //                               ^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] STATIC_WARNING.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'Contravariant<String>' can't be assigned to the parameter type 'Contravariant<int>'.

  // String <: T <: int is not a valid constraint.
  inferCovContra(Covariant<String>(), Contravariant<int>());
//^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
  //                                  ^^^^^^^^^^^^^^^^^^^^
  // [analyzer] STATIC_WARNING.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'Contravariant<int>' can't be assigned to the parameter type 'Contravariant<String>'.

  // Middle <: T <: Lower is not a valid constraint
  inferCovContra(Covariant<Middle>(), Contravariant<Lower>());
//^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
  //                                  ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CAST_NEW_EXPR
  // [cfe] The constructor returns type 'Contravariant<Lower>' that isn't of expected type 'Contravariant<Middle>'.

  // Upper <: T <: Lower is not a valid constraint
  inferCovContra(Covariant<Upper>(), Contravariant<Lower>());
//^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
  //                                 ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CAST_NEW_EXPR
  // [cfe] The constructor returns type 'Contravariant<Lower>' that isn't of expected type 'Contravariant<Upper>'.

  // Upper <: T <: Middle is not a valid constraint
  inferCovContra(Covariant<Upper>(), Contravariant<Middle>());
//^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
  //                                 ^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CAST_NEW_EXPR
  // [cfe] The constructor returns type 'Contravariant<Middle>' that isn't of expected type 'Contravariant<Upper>'.
}
