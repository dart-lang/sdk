// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Context type is propagated down in collection literals.

import '../dot_shorthand_helper.dart';

void main() {
  // Enum
  var colorList = <Color>[.blue, .green, .red];
  var colorSet = <Color>{.blue, .red};
  var colorMap = <Color, Color>{.blue: .blue, .green: .red};
  var colorMap2 = <Color, (Color, Color)>{.red: (.blue, .green)};

  // Class
  var integerList = <Integer>[.one, .two, .one];
  var integerSet = <Integer>{.one, .two};
  var integerMap = <Integer, Integer>{
    .one: .two,
    .two: .two,
  };
  var integerMap2 = <Integer, (Integer, Integer)>{
    .one: (.one, .two),
    .two: (.two, .two),
  };

  // Extension type
  var integerExtList = <IntegerExt>[
    .one,
    .two,
    .one,
  ];
  var integerExtSet = <IntegerExt>{.one, .two};
  var integerExtMap = <IntegerExt, IntegerExt>{
    .one: .two,
    .two: .two,
  };
  var integerExtMap2 = <IntegerExt, (IntegerExt, IntegerExt)>{
    .one: (.one, .two),
    .two: (.two, .two),
  };

  // Mixin
  var integerMixinList = <IntegerMixin>[
    .mixinOne,
    .mixinTwo,
    .mixinOne,
  ];
  var integerMixinSet = <IntegerMixin>{
    .mixinOne,
    .mixinTwo,
  };
  var integerMixinMap = <IntegerMixin, IntegerMixin>{
    .mixinOne: .mixinTwo,
    .mixinTwo: .mixinTwo,
  };
  var integerMixinMap2 = <IntegerMixin, (IntegerMixin, IntegerMixin)>{
    .mixinOne: (.mixinOne, .mixinTwo),
    .mixinTwo: (.mixinTwo, .mixinTwo),
  };
}
