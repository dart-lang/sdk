// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing erroneous ways of using shorthands with the `==` and `!=` operators.

import '../dot_shorthand_helper.dart';

class ConstConstructorAssert {
  const ConstConstructorAssert.blue(Color color)
      : assert(.blue == color);
        //     ^^^^^
        // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
        //      ^^^^
        // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
        // [cfe] No type was provided to find the dot shorthand 'blue'.

  const ConstConstructorAssert.notBlue(Color color)
      : assert(.blue != color);
        //     ^^^^^
        // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
        //      ^^^^
        // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
        // [cfe] No type was provided to find the dot shorthand 'blue'.

  const ConstConstructorAssert.one(Integer integer)
      : assert(.constOne == integer);
        //     ^^^^^^^^^
        // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
        //      ^^^^^^^^
        // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
        // [cfe] No type was provided to find the dot shorthand 'constOne'.

  const ConstConstructorAssert.notOne(Integer integer)
      : assert(.constOne != integer);
        //     ^^^^^^^^^
        // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
        //      ^^^^^^^^
        // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
        // [cfe] No type was provided to find the dot shorthand 'constOne'.

  const ConstConstructorAssert.oneExt(IntegerExt integer)
      : assert(.constOne == integer);
        //     ^^^^^^^^^
        // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
        //      ^^^^^^^^
        // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
        // [cfe] No type was provided to find the dot shorthand 'constOne'.

  const ConstConstructorAssert.notOneExt(IntegerExt integer)
      : assert(.constOne != integer);
        //     ^^^^^^^^^
        // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
        //      ^^^^^^^^
        // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
        // [cfe] No type was provided to find the dot shorthand 'constOne'.

  const ConstConstructorAssert.oneMixin(IntegerMixin integer)
      : assert(.mixinConstOne == integer);
        //     ^^^^^^^^^^^^^^
        // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
        //      ^^^^^^^^^^^^^
        // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
        // [cfe] No type was provided to find the dot shorthand 'mixinConstOne'.

  const ConstConstructorAssert.notOneMixin(IntegerMixin integer)
      : assert(.mixinConstOne != integer);
        //     ^^^^^^^^^^^^^^
        // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
        //      ^^^^^^^^^^^^^
        // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
        // [cfe] No type was provided to find the dot shorthand 'mixinConstOne'.
}

void notSymmetrical(Color color, Integer integer, IntegerExt integerExt,
    IntegerMixin integerMixin) {
  const constColor = Color.blue;

  const bool symBlueEq = .blue == constColor;
  //                     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                      ^
  // [cfe] No type was provided to find the dot shorthand 'blue'.

  const bool symBlueNeq = .blue != constColor;
  //                      ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                       ^
  // [cfe] No type was provided to find the dot shorthand 'blue'.

  const constInteger = Integer.constOne;
  const bool symOneEq = .one == constInteger;
  //                    ^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                     ^
  // [cfe] No type was provided to find the dot shorthand 'one'.

  const bool symOneNeq = .one != constInteger;
  //                     ^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                      ^
  // [cfe] No type was provided to find the dot shorthand 'one'.

  const constIntegerExt = IntegerExt.constOne;
  const bool symOneExtEq = .one == constIntegerExt;
  //                       ^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                        ^
  // [cfe] No type was provided to find the dot shorthand 'one'.

  const bool symOneExtNeq = .one != constIntegerExt;
  //                        ^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                         ^
  // [cfe] No type was provided to find the dot shorthand 'one'.

  if (.blue == color) print('not ok');
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //   ^
  // [cfe] No type was provided to find the dot shorthand 'blue'.

  if (.blue != color) print('not ok');
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //   ^
  // [cfe] No type was provided to find the dot shorthand 'blue'.

  if (.one == integer) print('not ok');
  //  ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //   ^
  // [cfe] No type was provided to find the dot shorthand 'one'.

  if (.one != integer) print('not ok');
  //  ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //   ^
  // [cfe] No type was provided to find the dot shorthand 'one'.

  if (.one == integerExt) print('not ok');
  //  ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //   ^
  // [cfe] No type was provided to find the dot shorthand 'one'.

  if (.one != integerExt) print('not ok');
  //  ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //   ^
  // [cfe] No type was provided to find the dot shorthand 'one'.

  if (.mixinOne == integerMixin) print('not ok');
  //  ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //   ^
  // [cfe] No type was provided to find the dot shorthand 'mixinOne'.

  if (.mixinOne != integerMixin) print('not ok');
  //  ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //   ^
  // [cfe] No type was provided to find the dot shorthand 'mixinOne'.
}

void rhsNeedsToBeShorthand(Color color, Integer integer, IntegerExt integerExt,
    IntegerMixin integerMixin, bool condition) {
  const Color constColor = Color.red;
  const Object obj = true;
  const bool constCondition = obj as bool;

  const bool rhsColorEq = constColor == (constCondition ? .red : .green);
  //                                                      ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                                       ^
  // [cfe] No type was provided to find the dot shorthand 'red'.
  //                                                             ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                                              ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [cfe] No type was provided to find the dot shorthand 'green'.

  const bool rhsColorNeq = constColor != (constCondition ? .red : .green);
  //                                                       ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                                        ^
  // [cfe] No type was provided to find the dot shorthand 'red'.
  //                                                              ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                                               ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [cfe] No type was provided to find the dot shorthand 'green'.

  if (color == (.red)) print('not ok');
  //            ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //             ^
  // [cfe] No type was provided to find the dot shorthand 'red'.

  if (color != (.red)) print('not ok');
  //            ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //             ^
  // [cfe] No type was provided to find the dot shorthand 'red'.

  if (color == (condition ? .red : .green)) print('not ok');
  //                        ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                         ^
  // [cfe] No type was provided to find the dot shorthand 'red'.
  //                               ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                ^
  // [cfe] No type was provided to find the dot shorthand 'green'.

  if (color != (condition ? .red : .green)) print('not ok');
  //                        ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                         ^
  // [cfe] No type was provided to find the dot shorthand 'red'.
  //                               ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                ^
  // [cfe] No type was provided to find the dot shorthand 'green'.

  if (color case == (constCondition ? .red : .green)) {
    //                                 ^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] The static getter or field 'red' isn't defined for the type 'Object?'.
    //                                        ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
    // [cfe] The static getter or field 'green' isn't defined for the type 'Object?'.
    print('not ok');
  }

  if (color case != (constCondition ? .red : .green)) {
    //                                 ^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] The static getter or field 'red' isn't defined for the type 'Object?'.
    //                                        ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
    // [cfe] The static getter or field 'green' isn't defined for the type 'Object?'.
    print('not ok');
  }

  const Integer constInteger = Integer.constOne;
  const bool rhsIntegerEq = constInteger == (constCondition ? .constOne : .constTwo);
  //                                                          ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                                           ^
  // [cfe] No type was provided to find the dot shorthand 'constOne'.
  //                                                                      ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                                                       ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [cfe] No type was provided to find the dot shorthand 'constTwo'.

  const bool rhsIntegerNeq = constInteger != (constCondition ? .constOne : .constTwo);
  //                                                           ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                                            ^
  // [cfe] No type was provided to find the dot shorthand 'constOne'.
  //                                                                       ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                                                        ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [cfe] No type was provided to find the dot shorthand 'constTwo'.

  if (integer == (condition ? .constOne : .constTwo)) {
    //                        ^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //                         ^
    // [cfe] No type was provided to find the dot shorthand 'constOne'.
    //                                    ^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //                                     ^
    // [cfe] No type was provided to find the dot shorthand 'constTwo'.
    print('not ok');
  }

  if (integer != (condition ? .constOne : .constTwo)) {
    //                        ^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //                         ^
    // [cfe] No type was provided to find the dot shorthand 'constOne'.
    //                                    ^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //                                     ^
    // [cfe] No type was provided to find the dot shorthand 'constTwo'.
    print('not ok');
  }

  if (integer case == (constCondition ? .constOne : .constTwo)) {
    //                                   ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] The static getter or field 'constOne' isn't defined for the type 'Object?'.
    //                                               ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
    // [cfe] The static getter or field 'constTwo' isn't defined for the type 'Object?'.
    print('not ok');
  }

  if (integer case != (constCondition ? .constOne : .constTwo)) {
    //                                   ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] The static getter or field 'constOne' isn't defined for the type 'Object?'.
    //                                               ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
    // [cfe] The static getter or field 'constTwo' isn't defined for the type 'Object?'.
    print('not ok');
  }

  const IntegerExt constIntegerExt = IntegerExt.constOne;
  const bool rhsIntegerExtEq = constIntegerExt == (constCondition ? .constOne : .constTwo);
  //                                                                ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                                                 ^
  // [cfe] No type was provided to find the dot shorthand 'constOne'.
  //                                                                            ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                                                             ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [cfe] No type was provided to find the dot shorthand 'constTwo'.

  const bool rhsIntegerExtNeq = constIntegerExt != (constCondition ? .constOne : .constTwo);
  //                                                                 ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                                                  ^
  // [cfe] No type was provided to find the dot shorthand 'constOne'.
  //                                                                             ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                                                              ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [cfe] No type was provided to find the dot shorthand 'constTwo'.

  if (integerExt == (condition ? .constOne : .constTwo)) {
    //                           ^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //                            ^
    // [cfe] No type was provided to find the dot shorthand 'constOne'.
    //                                       ^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //                                        ^
    // [cfe] No type was provided to find the dot shorthand 'constTwo'.
    print('not ok');
  }

  if (integerExt != (condition ? .constOne : .constTwo)) {
    //                           ^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //                            ^
    // [cfe] No type was provided to find the dot shorthand 'constOne'.
    //                                       ^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //                                        ^
    // [cfe] No type was provided to find the dot shorthand 'constTwo'.
    print('not ok');
  }

  if (integerExt case == (constCondition ? .constOne : .constTwo)) {
    //                                      ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] The static getter or field 'constOne' isn't defined for the type 'Object?'.
    //                                                  ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
    // [cfe] The static getter or field 'constTwo' isn't defined for the type 'Object?'.
    print('not ok');
  }

  if (integerExt case != (constCondition ? .constOne : .constTwo)) {
    //                                      ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] The static getter or field 'constOne' isn't defined for the type 'Object?'.
    //                                                  ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
    // [cfe] The static getter or field 'constTwo' isn't defined for the type 'Object?'.
    print('not ok');
  }

  const IntegerMixin constIntegerMixin = IntegerMixin.mixinConstOne;
  const bool rhsIntegerMixinEq = constIntegerMixin == (constCondition ? .mixinConstOne : .mixinConstTwo);
  //                                                                    ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                                                     ^
  // [cfe] No type was provided to find the dot shorthand 'mixinConstOne'.
  //                                                                                     ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                                                                      ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [cfe] No type was provided to find the dot shorthand 'mixinConstTwo'.

  const bool rhsIntegerMixinNeq = constIntegerMixin != (constCondition ? .mixinConstOne : .mixinConstTwo);
  //                                                                     ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                                                      ^
  // [cfe] No type was provided to find the dot shorthand 'mixinConstOne'.
  //                                                                                      ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //                                                                                       ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [cfe] No type was provided to find the dot shorthand 'mixinConstTwo'.

  if (integerMixin == (condition ? .mixinConstOne : .mixinConstTwo)) {
    //                             ^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //                              ^
    // [cfe] No type was provided to find the dot shorthand 'mixinConstOne'.
    //                                              ^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //                                               ^
    // [cfe] No type was provided to find the dot shorthand 'mixinConstTwo'.
    print('not ok');
  }

  if (integerMixin != (condition ? .mixinConstOne : .mixinConstTwo)) {
    //                             ^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //                              ^
    // [cfe] No type was provided to find the dot shorthand 'mixinConstOne'.
    //                                              ^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //                                               ^
    // [cfe] No type was provided to find the dot shorthand 'mixinConstTwo'.
    print('not ok');
  }

  if (integerMixin case == (constCondition ? .mixinConstOne : .mixinConstTwo)) {
    //                                        ^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] The static getter or field 'mixinConstOne' isn't defined for the type 'Object?'.
    //                                                         ^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
    // [cfe] The static getter or field 'mixinConstTwo' isn't defined for the type 'Object?'.
    print('not ok');
  }

  if (integerMixin case != (constCondition ? .mixinConstOne : .mixinConstTwo)) {
    //                                        ^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [cfe] The static getter or field 'mixinConstOne' isn't defined for the type 'Object?'.
    //                                                         ^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
    // [cfe] The static getter or field 'mixinConstTwo' isn't defined for the type 'Object?'.
    print('not ok');
  }
}

void objectContextType(Color color, Integer integer, IntegerExt integerExt,
    IntegerMixin integerMixin) {
  const Color constColor = Color.red;
  const bool contextTypeColorEq = (constColor as Object) == .blue;
  //                                                        ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  //                                                         ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'blue' isn't defined for the type 'Object'.

  const bool contextTypeColorNeq = (constColor as Object) != .blue;
  //                                                         ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  //                                                          ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'blue' isn't defined for the type 'Object'.

  if ((color as Object) == .blue) print('not ok');
  //                        ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'blue' isn't defined for the type 'Object'.

  if ((color as Object) case == .blue) print('not ok');
  //                            ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
  //                             ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'blue' isn't defined for the type 'Object'.

  if ((color as Object) != .blue) print('not ok');
  //                        ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'blue' isn't defined for the type 'Object'.

  if ((color as Object) case != .blue) print('not ok');
  //                            ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
  //                             ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'blue' isn't defined for the type 'Object'.

  const Integer constInteger = Integer.constOne;
  const bool contextTypeIntegerEq = (constInteger as Object) == .constTwo;
  //                                                            ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  //                                                             ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'constTwo' isn't defined for the type 'Object'.

  const bool contextTypeIntegerNeq = (constInteger as Object) != .constTwo;
  //                                                             ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  //                                                              ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'constTwo' isn't defined for the type 'Object'.

  if ((integer as Object) == .one) print('not ok');
  //                          ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'one' isn't defined for the type 'Object'.

  if ((integer as Object) case == .constOne) print('not ok');
  //                              ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
  //                               ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'constOne' isn't defined for the type 'Object'.

  if ((integer as Object) != .one) print('not ok');
  //                          ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'one' isn't defined for the type 'Object'.

  if ((integer as Object) case != .constOne) print('not ok');
  //                              ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
  //                               ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'constOne' isn't defined for the type 'Object'.

  const IntegerExt constIntegerExt = IntegerExt.constOne;
  const bool contextTypeIntegerExtEq = (constIntegerExt as Object) == .constTwo;
  //                                                                  ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  //                                                                   ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'constTwo' isn't defined for the type 'Object'.

  const bool contextTypeIntegerExtNeq = (constIntegerExt as Object) != .constTwo;
  //                                                                   ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  //                                                                    ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'constTwo' isn't defined for the type 'Object'.

  if ((integerExt as Object) == .one) print('not ok');
  //                             ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'one' isn't defined for the type 'Object'.

  if ((integerExt as Object) case == .constOne) print('not ok');
  //                                 ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
  //                                  ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'constOne' isn't defined for the type 'Object'.

  if ((integerExt as Object) != .one) print('not ok');
  //                             ^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'one' isn't defined for the type 'Object'.

  if ((integerExt as Object) case != .constOne) print('not ok');
  //                                 ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
  //                                  ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'constOne' isn't defined for the type 'Object'.

  const IntegerMixin constIntegerMixin = IntegerMixin.mixinConstOne;
  const bool contextTypeIntegerMixinEq = (constIntegerMixin as Object) == .mixinConstTwo;
  //                                                                      ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  //                                                                       ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'mixinConstTwo' isn't defined for the type 'Object'.

  const bool contextTypeIntegerMixinNeq = (constIntegerMixin as Object) != .mixinConstTwo;
  //                                                                       ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  //                                                                        ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'mixinConstTwo' isn't defined for the type 'Object'.

  if ((integerMixin as Object) == .mixinOne) print('not ok');
  //                               ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'mixinOne' isn't defined for the type 'Object'.

  if ((integerMixin as Object) case == .mixinConstOne) print('not ok');
  //                                   ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
  //                                    ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'mixinConstOne' isn't defined for the type 'Object'.

  if ((integerMixin as Object) != .mixinOne) print('not ok');
  //                               ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'mixinOne' isn't defined for the type 'Object'.

  if ((integerMixin as Object) case != .mixinConstOne) print('not ok');
  //                                   ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_RELATIONAL_PATTERN_EXPRESSION
  //                                    ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_UNDEFINED_MEMBER
  // [cfe] The static getter or field 'mixinConstOne' isn't defined for the type 'Object'.
}

void typeParameterContext<C extends Color, T extends Object>(C color, T value) {
  if (color == .red) print('not ok');
  //           ^^^^
  // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
  //            ^
  // [cfe] The static getter or field 'red' isn't defined for the type 'C'.
  if (value is Color) {
    if (value == .red) print('not ok');
    //           ^^^^
    // [analyzer] COMPILE_TIME_ERROR.DOT_SHORTHAND_MISSING_CONTEXT
    //            ^
    // [cfe] The static getter or field 'red' isn't defined for the type 'T'.
  }
}

void main() {
  Color color = .blue;
  Integer integer = .one;
  IntegerExt integerExt = .one;
  IntegerMixin integerMixin = .mixinOne;

  notSymmetrical(color, integer, integerExt, integerMixin);
  rhsNeedsToBeShorthand(color, integer, integerExt, integerMixin, true);
  rhsNeedsToBeShorthand(color, integer, integerExt, integerMixin, false);
  objectContextType(color, integer, integerExt, integerMixin);

  typeParameterContext(color, integer);
  typeParameterContext(color, Color.red);

  // Test the constant evaluation for dot shorthands in const constructor
  // asserts.
  const ConstConstructorAssert.blue(Color.blue);
  // [error column 3, length 45]
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
  const ConstConstructorAssert.notBlue(Color.red);
  // [error column 3, length 47]
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
  const ConstConstructorAssert.one(Integer.constOne);
  // [error column 3, length 50]
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
  const ConstConstructorAssert.notOne(Integer.constTwo);
  // [error column 3, length 53]
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
  const ConstConstructorAssert.oneExt(IntegerExt.constOne);
  // [error column 3, length 56]
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
  const ConstConstructorAssert.notOneExt(IntegerExt.constTwo);
  // [error column 3, length 59]
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
  const ConstConstructorAssert.oneMixin(IntegerMixin.mixinConstOne);
  // [error column 3, length 65]
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
  const ConstConstructorAssert.notOneMixin(IntegerMixin.mixinConstTwo);
  // [error column 3, length 68]
  // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
}
