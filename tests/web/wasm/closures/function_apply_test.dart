// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  // Prevent constant propagation of closure into `Function.apply`.
  for (final (name, closure) in <(String, Function)>[
    ('static1', static1),
    ('static2', static2),
  ]) {
    test('$name: 1 missing-b', closure, [1]);
    test('$name: 1 2', closure, [1, 2]);
  }
}

String static1(a, [b = 'missing-b']) => 'static1: $a $b';
String static2(a, [b = 'missing-b']) => 'static2: $a $b';

void test(String expected, Function function, List positional) {
  Expect.equals(expected, Function.apply(function, positional));
  final oneMoreThanAllowed = [
    for (int i = positional.length; i < 3; ++i) 'extra$i',
  ];
  Expect.throwsNoSuchMethodError(
    () => Function.apply(function, [...positional, ...oneMoreThanAllowed]),
  );
}
