// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Context type is propagated down in cascades.

import '../dot_shorthand_helper.dart';

class Cascade {
  late Color color;
  late Integer integer;
  late IntegerExt integerExt;
  late IntegerMixin integerMixin;
}

class CascadeCollection {
  late List<Color> colorList;
  late Set<Color> colorSet;
  late Map<Color, Color> colorMap;
  late Map<Color, (Color, Color)> colorMap2;

  late List<Integer> integerList;
  late Set<Integer> integerSet;
  late Map<Integer, Integer> integerMap;
  late Map<Integer, (Integer, Integer)> integerMap2;

  late List<IntegerExt> integerExtList;
  late Set<IntegerExt> integerExtSet;
  late Map<IntegerExt, IntegerExt> integerExtMap;
  late Map<IntegerExt, (IntegerExt, IntegerExt)> integerExtMap2;

  late List<IntegerMixin> integerMixinList;
  late Set<IntegerMixin> integerMixinSet;
  late Map<IntegerMixin, IntegerMixin> integerMixinMap;
  late Map<IntegerMixin, (IntegerMixin, IntegerMixin)> integerMixinMap2;
}

class CascadeMethod {
  void color(Color color) => print(color);
  void integer(Integer integer) => print(integer);
  void integerExt(IntegerExt integer) => print(integer);
  void integerMixin(IntegerMixin integer) => print(integer);
}

void main() {
  Cascade()
    ..color = .red
    ..integer = .one
    ..integerExt = .one
    ..integerMixin = .mixinOne;

  dynamic mayBeNull = null;
  Cascade()
    ..color = mayBeNull ?? .red
    ..integer = mayBeNull ?? .one
    ..integerExt = mayBeNull ?? .one
    ..integerMixin = mayBeNull ?? .mixinOne;

  CascadeCollection()
    // Enum
    ..colorList = [.blue, .green, .red]
    ..colorSet = {.blue, .red}
    ..colorMap = {.blue: .blue, .green: .red}
    ..colorMap2 = {.red: (.blue, .green)}
    // Class
    ..integerList = [.one, .two, .one]
    ..integerSet = {.one, .two}
    ..integerMap = {.one: .two, .two: .two}
    ..integerMap2 = {
      .one: (.one, .two),
      .two: (.two, .two),
    }
    // Extension type
    ..integerExtList = [.one, .two, .one]
    ..integerExtSet = {.one, .two}
    ..integerExtMap = {
      .one: .two,
      .two: .two,
    }
    ..integerExtMap2 = {
      .one: (.one, .two),
      .two: (.two, .two),
    }
    // Mixin
    ..integerMixinList = [
      .mixinOne,
      .mixinTwo,
      .mixinOne,
    ]
    ..integerMixinSet = {.mixinOne, .mixinTwo}
    ..integerMixinMap = {
      .mixinOne: .mixinTwo,
      .mixinTwo: .mixinTwo,
    }
    ..integerMixinMap2 = {
      .mixinOne: (.mixinOne, .mixinTwo),
      .mixinTwo: (.mixinTwo, .mixinTwo),
    };

  CascadeMethod()
    ..color(.red)
    ..integer(.one)
    ..integerExt(.one)
    ..integerMixin(.mixinOne);

  Color color = .blue..toString();
  Integer integer = .one..toString();
  IntegerExt integerExt = .one..toString();
  IntegerMixin integerMixin = .mixinOne..toString();
}
