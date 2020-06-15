// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: unused_local_variable

// Static tests for inheriting types on overriding members.

// If a member `m` omits any parameter type, or the return type, and
// one or more of the immediate superinterfaces have a member named
// `m`: Find the combined member signature `s` for `m` in the immediate
// superinterfaces. A compile-time error occurs if it does not exist.
// Otherwise, each missing type annotation of a parameter is obtained
// from the corresponding parameter in `s`, and the return type, if
// missing, is obtained from `s`. If there is no corresponding
// parameter in `s`, the inferred type annotation is `dynamic`.
//
// Only types are inherited. Other modifiers and annotations are not.
// This includes `final`, `required` and any annotations
// or default values.
// (The `covariant` keyword is not inherited, but its semantics
// are so it's impossible to tell the difference).
//
// For getters and setters, if both are present, subclasses inherit the type of
// the corresponding superclass member.
// If the superclass has only a setter or a getter, subclasses inherit that type
// for both getters and setters.

// Incompatible `foo` signatures.
abstract class IIntInt {
  int foo(int x);
}

abstract class IIntDouble {
  double foo(int x);
}

abstract class IDoubleInt {
  int foo(double x);
}

abstract class IDoubleDouble {
  double foo(double x);
}

// If the superinterfaces do not have a most specific member signature,
// then omitting any parameter or return type is an error.

abstract class CInvalid1 implements IIntInt, IIntDouble {
  /*indent*/ foo(x);
  //         ^^^
  // [analyzer] unspecified
  // [cfe] unspecified
}

abstract class CInvalid2 implements IIntInt, IDoubleInt {
  /*indent*/ foo(x);
  //         ^^^
  // [analyzer] unspecified
  // [cfe] unspecified
}

abstract class CInvalid3 implements IIntInt, IDoubleDouble {
  /*indent*/ foo(x);
  //         ^^^
  // [analyzer] unspecified
  // [cfe] unspecified
}

// Even if the conflicting super-parameter/return type is given a type.
abstract class CInvalid4 implements IIntInt, IIntDouble {
  Never foo(x);
  //    ^^^
  // [analyzer] unspecified
  // [cfe] unspecified
}

abstract class CInvalid5 implements IIntInt, IDoubleInt {
  /*indent*/ foo(num x);
  //         ^^^
  // [analyzer] unspecified
  // [cfe] unspecified
}

// Even if the omitted parameter doesn't exist in the super-interfaces.
abstract class CInvalid6 implements IIntInt, IDoubleInt {
  Never foo(num x, [y]);
  //    ^^^
  // [analyzer] unspecified
  // [cfe] unspecified
}

// And even if there is no real conflict.
abstract class IOptx {
  int foo({int x});
}

abstract class IOpty {
  int foo({int y});
}

abstract class CInvalid7 implements IOptx, IOpty {
  /*indent*/ foo({int x, int y});
  //         ^^^
  // [analyzer] unspecified
  // [cfe] unspecified
}

// The type of unconstrained omitted types is `dynamic`.
class CInherit1 implements IOptx {
  foo({x = 0, y = 0}) {
    // Type of `y` is `dynamic`.
    Object? tmp;
    y = tmp; // Top type.
    Null tmp2 = y; // And implicit downcast.
    y.arglebargle(); // And unsound member invocations.

    // x is exactly int.
    // Assignable to int and usable as int.
    int intVar = x;
    x = x.toRadixString(16).length;
    // And not dynamic.
    /*indent*/ x.arglebargle();
    //           ^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // Return type is exactly int.
    if (x == 0) {
      num tmp3 = x;
      return tmp3; // Does not allow returning a supertype of int.
      //     ^^^^
      // [analyzer] unspecified
      // [cfe] unspecified
    }
    // Allows returning int.
    return intVar;
  }

  // No supertype signature, infer `dynamic` for every type.
  bar(x) {
    // x is Object?.
    Object? tmp;
    x = tmp; // A top type since Object? is assignable to it.
    Null tmp2 = x; // Implicit downcast.
    x.arglebargle(); // Unsafe invocations.

    // Return type is `dynamic` when calling `bar`.
    var ret = bar(x);
    ret = tmp;
    tmp2 = ret;
    ret.arglebargle();

    // And definitely a top type when returning.
    return tmp;
  }
}

/// Do not inherit `required`.
class IReq {
  void foo({required int x}) {}
}

class CInvalid8 implements IReq {
  // Do not inherit `required` if there is a type.
  foo({num x}) {}
  //       ^
  // [analyzer] COMPILE_TIME_ERROR.MISSING_DEFAULT_VALUE_FOR_PARAMETER
  // [cfe] unspecified
}

class CInvalid9 implements IReq {
  // Do not inherit `required` if there is no type.
  void foo({x}) {}
  //        ^
  // [analyzer] COMPILE_TIME_ERROR.MISSING_DEFAULT_VALUE_FOR_PARAMETER
  // [cfe] unspecified
}

abstract class INonNullable {
  foo({num x});
}

class CInvalid10 implements INonNullable {
  // Inherit type even when it would be invalid in the supertype, if it had been
  // non-abstract.
  foo({x}) {}
  //   ^
  // [analyzer] COMPILE_TIME_ERROR.MISSING_DEFAULT_VALUE_FOR_PARAMETER
  // [cfe] unspecified
}

/// Do not inherit default value implicitly.
class IDefault {
  int foo({int x = 0}) => x;
}

class CInvalid11 implements IDefault {
  foo({x}) => x;
  //   ^
  // [analyzer] COMPILE_TIME_ERROR.MISSING_DEFAULT_VALUE_FOR_PARAMETER
  // [cfe] unspecified
  //   ^
  // [analyzer] STATIC_WARNING.INVALID_OVERRIDE_DIFFERENT_DEFAULT_VALUES_NAMED
}

// Inherits type variables, even with different names.
class CGeneric<T> {
  T foo(T x) => x;

  R bar<R>(R x) => x;
}

class CInheritGeneric<S> implements CGeneric<S> {
  foo(x) {
    // x has type exactly S.
    // Assignable both ways.
    S tmp = x;
    x = tmp;
    // And not dynamic.
    /*indent*/ x.arglebargle();
    //           ^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // Return type is S.
    tmp = foo(x);
    return tmp;
  }

  bar<Q>(x) {
    // x has type exactly Q.
    // Assignable both ways.
    Q tmp = x;
    x = tmp;
    // And not dynamic.
    /*indent*/ x.arglebargle();
    //           ^^^^^^^^^^^
    // [analyzer] unspecified
    // [cfe] unspecified

    // Return type is Q.
    tmp = bar<Q>(x);
    return tmp;
  }
}

main() {}
