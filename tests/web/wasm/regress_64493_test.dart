// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

final one = int.parse('1');
final two = int.parse('2');

class Sub1 {
  String fooNamed({int? a}) => 'Sub1($a)';

  String fooPositional([int? a]) => 'Sub1($a)';
}

class Sub2 extends Sub1 {
  @override
  String fooNamed({int? a, int? b}) => 'Sub2($a, $b)';

  @override
  String fooPositional([int? a, int? b]) => 'Sub2($a, $b)';
}

// Exercises `_ClosureTrampolineGenerator`: typed calls on tear-off closures
// dispatch through the closure vtable's signature-specific trampolines.
void testClosureTrampolineGenerator(
  String Function({int? a}) fooNamedTearOff,
  String Function([int? a]) fooPositionalTearOff,
) {
  Expect.equals('Sub1(1)', fooNamedTearOff(a: one));
  Expect.equals('Sub1(1)', fooPositionalTearOff(one));
}

// Exercises `_ClosureDynamicEntryGenerator`: `Function.apply` dispatches
// through the closure vtable's dynamic call entry.
void testClosureDynamicEntryGenerator(
  Function fooNamedTearOff,
  Function fooPositionalTearOff,
) {
  Expect.equals(
    'Sub1(1)',
    Function.apply(fooNamedTearOff, const [], {#a: one}),
  );
  Expect.equals('Sub1(1)', Function.apply(fooPositionalTearOff, [one]));
}

void main() {
  // The `Sub2` methods aren't torn off and all call sites pass integers, so TFA
  // infers `int` types for the parameters while the selector's `ParameterInfo`
  // retains `NullConstant` as `b`'s default.
  final Sub2 s2 = Sub2();
  Expect.equals('Sub2(1, 2)', s2.fooNamed(a: one, b: two));
  Expect.equals('Sub2(1, 2)', s2.fooPositional(one, two));

  final Sub1 s1 = Sub1();
  final fooNamedTearOff = one == 1 ? s1.fooNamed : ({int? a}) => 'other($a)';
  final fooPositionalTearOff = one == 1
      ? s1.fooPositional
      : ([int? a]) => 'other($a)';

  testClosureTrampolineGenerator(fooNamedTearOff, fooPositionalTearOff);
  testClosureDynamicEntryGenerator(fooNamedTearOff, fooPositionalTearOff);
}
