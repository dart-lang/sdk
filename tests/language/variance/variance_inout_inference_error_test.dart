// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests local inference errors for the `inout` variance modifier.

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
  // Middle <: T <: Middle and int <: T <: int are not valid constraints.
  inferInvInv(Invariant<Middle>(), Invariant<int>());
//            ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
// [cfe] The argument type 'Invariant<Middle>' can't be assigned to the parameter type 'Invariant<Object>'.
//                                 ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
// [cfe] The argument type 'Invariant<int>' can't be assigned to the parameter type 'Invariant<Object>'.

  // Middle <: T <: Middle and Upper <: T <: Upper are not valid constraints.
  inferInvInv(Invariant<Middle>(), Invariant<Upper>());
//            ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
// [cfe] The argument type 'Invariant<Middle>' can't be assigned to the parameter type 'Invariant<Upper>'.

  // Middle <: T <: Middle and Lower <: T <: Lower are not valid constraints.
  inferInvInv(Invariant<Middle>(), Invariant<Lower>());
//                                 ^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
// [cfe] The argument type 'Invariant<Lower>' can't be assigned to the parameter type 'Invariant<Middle>'.

  // Upper <: T
  // Middle <: T <: Middle
  // Upper <: T <: Middle is not a valid constraint.
  inferInvCov(Invariant<Middle>(), Covariant<Upper>());
//            ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
// [cfe] The argument type 'Invariant<Middle>' can't be assigned to the parameter type 'Invariant<Upper>'.

  // T <: Lower
  // Middle <: T <: Lower
  // Middle <: T <: Lower is not a valid constraint
  inferInvContra(Invariant<Middle>(), Contravariant<Lower>());
//                                    ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
// [cfe] The argument type 'Contravariant<Lower>' can't be assigned to the parameter type 'Contravariant<Middle>'.
}
