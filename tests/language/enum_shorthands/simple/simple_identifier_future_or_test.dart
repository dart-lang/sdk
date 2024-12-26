// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `FutureOr<S>` denotes the same namespace as `S` for enum shorthands.

// SharedOptions=--enable-experiment=enum-shorthands

import 'dart:async';

import '../enum_shorthand_helper.dart';

class ColorFutureOrContext {
  final FutureOr<Color> color;
  final FutureOr<Color?> nullableColor;
  ColorFutureOrContext(this.color, this.nullableColor);
  ColorFutureOrContext.named({this.color = .blue, this.nullableColor});
  ColorFutureOrContext.optional([this.color = .blue, this.nullableColor]);
}

class IntegerFutureOrContext {
  final FutureOr<Integer> integer;
  final FutureOr<Integer?> nullableInteger;
  IntegerFutureOrContext(this.integer, this.nullableInteger);
  IntegerFutureOrContext.named({this.integer = .constOne, this.nullableInteger});
  IntegerFutureOrContext.optional([this.integer = .constOne, this.nullableInteger]);
}

class IntegerExtFutureOrContext {
  final FutureOr<IntegerExt> integer;
  final FutureOr<IntegerExt?> nullableInteger;
  IntegerExtFutureOrContext(this.integer, this.nullableInteger);
  IntegerExtFutureOrContext.named({this.integer = .constOne, this.nullableInteger});
  IntegerExtFutureOrContext.optional([this.integer = .constOne, this.nullableInteger]);
}

class IntegerMixinFutureOrContext {
  final FutureOr<IntegerMixin> integer;
  final FutureOr<IntegerMixin?> nullableInteger;
  IntegerMixinFutureOrContext(this.integer, this.nullableInteger);
  IntegerMixinFutureOrContext.named({this.integer = .mixinConstOne, this.nullableInteger});
  IntegerMixinFutureOrContext.optional([this.integer = .mixinConstOne, this.nullableInteger]);
}

void main() {
  // Enum
  FutureOr<Color> color = .blue;
  FutureOr<Color?> nullableColor = .blue;
  const FutureOr<Color> constColor = .blue;
  const FutureOr<Color?> constNullableColor = .blue;
  switch (color) {
    case .blue:
      print('blue');
    case .red:
      print('red');
    case .green:
      print('green');
  }

  var colorList = <FutureOr<Color>>[.blue, .green, .red];
  var nullableColorList = <FutureOr<Color?>>[.blue, .green, .red];

  var colorContextPositional = ColorFutureOrContext(.blue, .red);
  var colorContextNamed = ColorFutureOrContext.named(color: .blue, nullableColor: .red);
  var colorContextOptional = ColorFutureOrContext.optional(.blue, .red);

  // Class
  FutureOr<Integer> integer = .one;
  FutureOr<Integer?> nullableInteger = .one;
  const FutureOr<Integer> constInteger = .constOne;
  const FutureOr<Integer?> constNullableInteger = .constOne;

  var integerList = <FutureOr<Integer>>[.one, .two, .one];
  var nullableIntegerList = <FutureOr<Integer?>>[.one, .two, .one];

  var integerContextPositional = IntegerFutureOrContext(.one, .two);
  var integerContextNamed = IntegerFutureOrContext.named(integer: .one, nullableInteger: .two);
  var integerContextOptional = IntegerFutureOrContext.optional(.one, .two);

  // Extension type
  FutureOr<IntegerExt> integerExt = .one;
  FutureOr<IntegerExt?> nullableIntegerExt = .one;
  const FutureOr<IntegerExt> constIntegerExt = .constOne;
  const FutureOr<IntegerExt?> constNullableIntegerExt = .constOne;

  var integerExtList = <FutureOr<IntegerExt>>[.one, .two, .one];
  var nullableIntegerExtList = <FutureOr<IntegerExt?>>[.one, .two, .one];

  var integerExtContextPositional = IntegerExtFutureOrContext(.one, .two);
  var integerExtContextNamed = IntegerExtFutureOrContext.named(integer: .one, nullableInteger: .two);
  var integerExtContextOptional = IntegerExtFutureOrContext.optional(.one, .two);

  // Mixin
  FutureOr<IntegerMixin> integerMixin = .mixinOne;
  FutureOr<IntegerMixin?> nullableIntegerMixin = .mixinOne;
  const FutureOr<IntegerMixin> constIntegerMixin = .mixinConstOne;
  const FutureOr<IntegerMixin?> constNullableIntegerMixin = .mixinConstOne;

  var integerMixinList = <FutureOr<IntegerExt>>[.one, .two, .one];
  var nullableIntegerMixinList = <FutureOr<IntegerExt?>>[.one, .two, .one];

  var integerMixinContextPositional = IntegerMixinFutureOrContext(.mixinOne, .mixinTwo);
  var integerMixinContextNamed = IntegerMixinFutureOrContext.named(integer: .mixinOne, nullableInteger: .mixinTwotwo);
  var integerMixinContextOptional = IntegerMixinFutureOrContext.optional(.mixinOne, .mixinTwo);
}

