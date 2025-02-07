// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing erroneous ways of using shorthands with the `==` and `!=` operators.

// SharedOptions=--enable-experiment=dot-shorthands

import '../enum_shorthand_helper.dart';

class ConstConstructorAssert {
  const ConstConstructorAssert.blue(Color color)
      : assert(.blue == color);
        //     ^
        // [analyzer] unspecified
        // [cfe] unspecified

  const ConstConstructorAssert.notBlue(Color color)
      : assert(.blue != color);
        //     ^
        // [analyzer] unspecified
        // [cfe] unspecified

  const ConstConstructorAssert.one(Integer integer)
      : assert(.constOne == integer);
        //     ^
        // [analyzer] unspecified
        // [cfe] unspecified

  const ConstConstructorAssert.notOne(Integer integer)
      : assert(.constOne != integer);
        //     ^
        // [analyzer] unspecified
        // [cfe] unspecified

  const ConstConstructorAssert.oneExt(IntegerExt integer)
      : assert(.constOne == integer);
        //     ^
        // [analyzer] unspecified
        // [cfe] unspecified

  const ConstConstructorAssert.notOneExt(IntegerExt integer)
      : assert(.constOne != integer);
        //     ^
        // [analyzer] unspecified
        // [cfe] unspecified

  const ConstConstructorAssert.oneMixin(IntegerMixin integer)
      : assert(.mixinConstOne == integer);
        //     ^
        // [analyzer] unspecified
        // [cfe] unspecified

  const ConstConstructorAssert.notOneMixin(IntegerMixin integer)
      : assert(.mixinConstOne != integer);
        //     ^
        // [analyzer] unspecified
        // [cfe] unspecified
}

void notSymmetrical(Color color, Integer integer, IntegerExt integerExt,
    IntegerMixin integerMixin) {
  const constColor = Color.blue;

  const bool symBlueEq = .blue == constColor;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool symBlueNeq = .blue != constColor;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const constInteger = Integer.constOne;
  const bool symOneEq = .one == constInteger;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool symOneNeq = .one != constInteger;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const constIntegerExt = IntegerExt.constOne;
  const bool symOneExtEq = .one == constIntegerExt;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool symOneExtNeq = .one != constIntegerExt;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.blue == color) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.blue != color) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.one == integer) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.one != integer) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.one == integerExt) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.one != integerExt) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.mixinOne == integerMixin) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (.mixinOne != integerMixin) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

void rhsNeedsToBeShorthand(Color color, Integer integer, IntegerExt integerExt,
    IntegerMixin integerMixin, bool condition) {
  const Color constColor = Color.red;
  const Object obj = true;
  const bool constCondition = obj as bool;

  const bool rhsColorEq = constColor == (constCondition ? .red : .green);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool rhsColorNeq = constColor != (constCondition ? .red : .green);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (color == (condition ? .red : .green)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (color != (condition ? .red : .green)) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (color case == (constCondition ? .red : .green)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (color case != (constCondition ? .red : .green)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  const Integer constInteger = Integer.constOne;
  const bool rhsIntegerEq = constInteger == (constCondition ? .constOne : .constTwo);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool rhsIntegerNeq = constInteger != (constCondition ? .constOne : .constTwo);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (integer == (condition ? .constOne : .constTwo)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (integer != (condition ? .constOne : .constTwo)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (integer case == (constCondition ? .constOne : .constTwo)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (integer case != (constCondition ? .constOne : .constTwo)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  const IntegerExt constIntegerExt = IntegerExt.constOne;
  const bool rhsIntegerExtEq = constIntegerExt == (constCondition ? .constOne : .constTwo);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool rhsIntegerExtNeq = constIntegerExt != (constCondition ? .constOne : .constTwo);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (integerExt == (condition ? .constOne : .constTwo)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (integerExt != (condition ? .constOne : .constTwo)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (integerExt case == (constCondition ? .constOne : .constTwo)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (integerExt case != (constCondition ? .constOne : .constTwo)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  const IntegerMixin constIntegerMixin = IntegerMixin.mixinConstOne;
  const bool rhsIntegerMixinEq = constIntegerMixin == (constCondition ? .mixinConstOne : .mixinConstTwo);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool rhsIntegerMixinNeq = constIntegerMixin != (constCondition ? .mixinConstOne : .mixinConstTwo);
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if (integerMixin == (condition ? .mixinConstOne : .mixinConstTwo)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (integerMixin != (condition ? .mixinConstOne : .mixinConstTwo)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (integerMixin case == (constCondition ? .mixinConstOne : .mixinConstTwo)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }

  if (integerMixin case != (constCondition ? .mixinConstOne : .mixinConstTwo)) {
    // ^
    // [analyzer] unspecified
    // [cfe] unspecified
    print('not ok');
  }
}

void objectContextType(Color color, Integer integer, IntegerExt integerExt,
    IntegerMixin integerMixin) {
  const Color constColor = Color.red;
  const bool contextTypeColorEq = (constColor as Object) == .blue;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool contextTypeColorNeq = (constColor as Object) != .blue;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((color as Object) == .blue) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((color as Object) case == .blue) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((color as Object) != .blue) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((color as Object) case != .blue) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const Integer constInteger = Integer.constOne;
  const bool contextTypeIntegerEq = (constInteger as Object) == .constTwo;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool contextTypeIntegerNeq = (constInteger as Object) != .constTwo;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((integer as Object) == .one) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((integer as Object) case == .constOne) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((integer as Object) != .one) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((integer as Object) case != .constOne) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const IntegerExt constIntegerExt = IntegerExt.constOne;
  const bool contextTypeIntegerExtEq = (constIntegerExt as Object) == .constTwo;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool contextTypeIntegerExtNeq = (constIntegerExt as Object) != .constTwo;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((integerExt as Object) == .one) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((integerExt as Object) case == .constOne) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((integerExt as Object) != .one) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((integerExt as Object) case != .constOne) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const IntegerMixin constIntegerMixin = IntegerMixin.mixinConstOne;
  const bool contextTypeIntegerMixinEq = (constIntegerMixin as Object) == .mixinConstTwo;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  const bool contextTypeIntegerMixinNeq = (constIntegerMixin as Object) != .mixinConstTwo;
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((integerMixin as Object) == .mixinOne) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((integerMixin as Object) case == .mixinConstOne) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((integerMixin as Object) != .mixinOne) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified

  if ((integerMixin as Object) case != .mixinConstOne) print('not ok');
  // ^
  // [analyzer] unspecified
  // [cfe] unspecified
}

void typeParameterContext<C extends Color, T extends Object>(C color, T value) {
  if (color == .red) print('not ok');
  //        ^
  // [analyzer] unspecified
  // [cfe] unspecified
  if (value is Color) {
    if (value == .red) print('not ok');
    //        ^
    // [analyzer] unspecified
    // [cfe] unspecified
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

  // Test the constant evaluation for enum shorthands in const constructor
  // asserts.
  const ConstConstructorAssert.blue(Color.blue);
  const ConstConstructorAssert.notBlue(Color.red);
  const ConstConstructorAssert.one(Integer.constOne);
  const ConstConstructorAssert.notOne(Integer.constTwo);
  const ConstConstructorAssert.oneExt(IntegerExt.constOne);
  const ConstConstructorAssert.notOneExt(IntegerExt.constTwo);
  const ConstConstructorAssert.oneMixin(IntegerMixin.mixinConstOne);
  const ConstConstructorAssert.notOneMixin(IntegerMixin.mixinConstTwo);
}
