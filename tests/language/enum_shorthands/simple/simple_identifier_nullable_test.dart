// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// `T?` denotes the same namespace as `T` for enum shorthands.

// SharedOptions=--enable-experiment=enum-shorthands

import '../enum_shorthand_helper.dart';

class NullableInteger {
  static NullableInteger? get one => NullableInteger(1);
  static NullableInteger? get two => NullableInteger(2);
  final int integer;
  NullableInteger(this.integer);
}

void main() {
  // Enum
  Color? color = .blue;
  const Color? constColor = .blue;
  switch (color) {
    case .blue:
      print('blue');
    case .red:
      print('red');
    case .green:
      print('green');
  }
  var colorList = <Color?>[.blue, .green, .red];

  // Class
  Integer? integer = .one;
  const Integer? constInteger = .constOne;
  var integerList = <Integer?>[.one, .two, .one];

  // Extension type
  IntegerExt? integerExt = .one;
  const IntegerExt? constIntegerExt = .constOne;
  var integerExtList = <Integer?>[.one, .two, .one];

  // Mixin
  IntegerMixin? integerMixin = .mixinOne;
  const IntegerMixin? constIntegerMixin = .mixinConstOne;
  var integerMixinList = <IntegerMixin?>[.one, .two, .one];

  // Null assertion on a nullable static member.
  NullableInteger? nullableInteger = .one;
  NullableInteger nullableIntegerAssert = .one!;
  var nullableIntegerMixinList = <NullableInteger>[.one!, .two!, .one!];
}

