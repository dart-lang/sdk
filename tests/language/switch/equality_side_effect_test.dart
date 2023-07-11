// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Switch cases may call user-defined `==` methods, which can have arbitrary
// side effects. Test that the cases are tried in order.

import "package:expect/expect.dart";

class SideEffect {
  static final effects = <String>[];

  static String test(int value) {
    effects.clear();

    switch (SideEffect(value)) {
      case const SideEffect(1):
        effects.add('match one');
      case const SideEffect(2):
        effects.add('match two');
      default:
        effects.add('no match');
    }

    return effects.join(', ');
  }

  final int value;

  const SideEffect(this.value);

  String toString() => 'S($value)';

  bool operator ==(Object other) {
    effects.add('$this == $other');
    return other is SideEffect && value == other.value;
  }
}

main() {
  Expect.equals('S(1) == S(1), match one', SideEffect.test(1));
  Expect.equals('S(1) == S(2), S(2) == S(2), match two', SideEffect.test(2));
  Expect.equals('S(1) == S(3), S(2) == S(3), no match', SideEffect.test(3));
}
