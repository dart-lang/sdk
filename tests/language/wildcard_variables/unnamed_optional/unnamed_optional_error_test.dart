// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that we still need default values for `this._` and `super._` and that
// we can't add default values to a `_` named parameter where you can't add 
// default values.

// SharedOptions=--enable-experiment=wildcard-variables

class SuperClass {
  SuperClass([int _]);
  //              ^
  // [analyzer] COMPILE_TIME_ERROR.MISSING_DEFAULT_VALUE_FOR_PARAMETER
  // [cfe] The parameter '_' can't have a value of 'null' because of its type 'int', but the implicit default value is 'null'.
  SuperClass.nullable([int? _]);
}
class SubClass extends SuperClass {
  final int _;
  SubClass([
    this._,
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.MISSING_DEFAULT_VALUE_FOR_PARAMETER
  // [cfe] The parameter '_' can't have a value of 'null' because of its type 'int', but the implicit default value is 'null'.
    super._,
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
  // [analyzer] COMPILE_TIME_ERROR.MISSING_DEFAULT_VALUE_FOR_PARAMETER
  // [cfe] Duplicated parameter name '_'.
  // [cfe] The parameter '_' can't have a value of 'null' because of its type 'int', but the implicit default value is 'null'.
  // [cfe] Type 'int' of the optional super-initializer parameter '_' doesn't allow 'null', but the parameter doesn't have a default value, and the default value can't be copied from the corresponding parameter of the super constructor.
  ]);
}
class TypedSubClass extends SuperClass {
  final int? _;
  TypedSubClass([
    int this._,
    //       ^
    // [analyzer] COMPILE_TIME_ERROR.MISSING_DEFAULT_VALUE_FOR_PARAMETER
    // [cfe] The parameter '_' can't have a value of 'null' because of its type 'int', but the implicit default value is 'null'.
    int super._,
    //        ^
    // [analyzer] COMPILE_TIME_ERROR.DUPLICATE_DEFINITION
    // [analyzer] COMPILE_TIME_ERROR.MISSING_DEFAULT_VALUE_FOR_PARAMETER
    // [cfe] Duplicated parameter name '_'.
    // [cfe] The parameter '_' can't have a value of 'null' because of its type 'int', but the implicit default value is 'null'.
    // [cfe] Type 'int' of the optional super-initializer parameter '_' doesn't allow 'null', but the parameter doesn't have a default value, and the default value can't be copied from the corresponding parameter of the super constructor.
  ]) : super.nullable();
}

// Function type parameters cannot have default values.
typedef F = void Function([int _ = 1]);
//                               ^
// [analyzer] SYNTACTIC_ERROR.DEFAULT_VALUE_IN_FUNCTION_TYPE
// [cfe] Can't have a default value in a function type.

// Redirecting factory constructors cannot have default values.
class ReClass {
  ReClass([int x = 0]);
  factory ReClass.redir([int _ = 0]) = ReClass;
  //                         ^
  // [analyzer] COMPILE_TIME_ERROR.DEFAULT_VALUE_IN_REDIRECTING_FACTORY_CONSTRUCTOR
  //                             ^
  // [cfe] Can't have a default value here because any default values of 'ReClass' would be used instead.
}
