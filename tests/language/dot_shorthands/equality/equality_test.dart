// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Testing the == and != behaviour for dot shorthands.

import '../dot_shorthand_helper.dart';

class ConstConstructorAssert {
  const ConstConstructorAssert.blue(Color color)
      : assert(color == .blue);

  const ConstConstructorAssert.notBlue(Color color)
      : assert(color != .blue);

  const ConstConstructorAssert.one(Integer integer)
      : assert(integer == .constOne);

  const ConstConstructorAssert.notOne(Integer integer)
      : assert(integer != .constOne);

  const ConstConstructorAssert.oneExt(IntegerExt integer)
      : assert(integer == .constOne);

  const ConstConstructorAssert.notOneExt(IntegerExt integer)
      : assert(integer != .constOne);

  const ConstConstructorAssert.oneMixin(IntegerMixin integer)
      : assert(integer == .mixinConstOne);

  const ConstConstructorAssert.notOneMixin(IntegerMixin integer)
      : assert(integer != .mixinConstOne);
}

void main() {
  // Enum
  Color color = .blue;
  const Color constColor = .blue;

  const bool constColorEq = constColor == .blue;
  const bool constColorNeq = constColor != .blue;

  if (color == .blue) print('ok');
  if (color case == .blue) print('ok');

  if (color != .blue) print('ok');
  if (color case != .blue) print('ok');

  // Class
  Integer integer = .one;
  const Integer constInteger = .constOne;

  const bool constIntegerEq = constInteger == .constOne;
  const bool constIntegerNeq = constInteger != .constOne;

  if (integer == .one) print('ok');
  if (integer case == .constOne) print('ok');

  if (integer != .one) print('ok');
  if (integer case != .constOne) print('ok');

  // Extension type
  IntegerExt integerExt = .one;
  const IntegerExt constIntegerExt = .constOne;

  const bool constIntegerExtEq = constIntegerExt == .constOne;
  const bool constIntegerExtNeq = constIntegerExt != .constOne;

  if (integerExt == .one) print('ok');
  if (integerExt case == .constOne) print('ok');

  if (integerExt != .one) print('ok');
  if (integerExt case != .constOne) print('ok');

  // Mixin
  IntegerMixin integerMixin = .mixinOne;
  const IntegerMixin constIntegerMixin = .mixinConstOne;

  const bool constIntegerMixinEq = constIntegerMixin == .mixinConstOne;
  const bool constIntegerMixinNeq = constIntegerMixin != .mixinConstOne;

  if (integerMixin == .mixinOne) print('ok');
  if (integerMixin case == .mixinConstOne) print('ok');

  if (integerMixin != .mixinOne) print('ok');
  if (integerMixin case != .mixinConstOne) print('ok');

  // Test the constant evaluation for dot shorthands in const constructor
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
