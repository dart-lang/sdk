// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Shorthands for simple identifiers and const simple identifiers.

import '../dot_shorthand_helper.dart';

class ColorContext {
  final Color? color;
  ColorContext(this.color);
  ColorContext.named({this.color});
  ColorContext.optional([this.color]);
}

class IntegerContext {
  final Integer? integer;
  IntegerContext(this.integer);
  IntegerContext.named({this.integer});
  IntegerContext.optional([this.integer]);
}

class IntegerExtContext {
  final IntegerExt? integer;
  IntegerExtContext(this.integer);
  IntegerExtContext.named({this.integer});
  IntegerExtContext.optional([this.integer]);
}

class IntegerMixinContext {
  final IntegerMixin? integer;
  IntegerMixinContext(this.integer);
  IntegerMixinContext.named({this.integer});
  IntegerMixinContext.optional([this.integer]);
}

void main() {
  // Enum
  Color color = .blue;
  const Color constColor = .blue;
  var colorContextPositional = ColorContext(.blue);
  var colorContextNamed = ColorContext.named(color: .blue);
  var colorContextOptional = ColorContext.optional(.blue);
  switch (color) {
    case .blue:
      print('blue');
    case .red:
      print('red');
    case .green:
      print('green');
  }

  // Class
  Integer integer = .one;
  const Integer constInteger = .constOne;
  var integerContextPositional = IntegerContext(.one);
  var integerContextNamed = IntegerContext.named(integer: .one);
  var integerContextOptional = IntegerContext.optional(.one);

  // Extension type
  IntegerExt integerExt = .one;
  const IntegerExt constIntegerExt = .constOne;
  var integerExtContextPositional = IntegerExtContext(.one);
  var integerExtContextNamed = IntegerExtContext.named(integer: .one);
  var integerExtContextOptional = IntegerExtContext.optional(.one);

  // Mixin
  IntegerMixin integerMixin = .mixinOne;
  const IntegerMixin constIntegerMixin = .mixinConstOne;
  var integerMixinContextPositional = IntegerMixinContext(.mixinOne);
  var integerMixinContextNamed = IntegerMixinContext.named(integer: .mixinOne);
  var integerMixinContextOptional = IntegerMixinContext.optional(.mixinOne);
}
