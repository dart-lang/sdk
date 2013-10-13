// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library symbol_validation_test;

import 'dart:mirrors';
import 'package:expect/expect.dart';

validSymbol(String string) {
  Expect.equals(string,
                MirrorSystem.getName(new Symbol(string)),
                'Valid symbol "$string" should be invertable');
  Expect.equals(string,
                MirrorSystem.getName(MirrorSystem.getSymbol(string)),
                'Valid symbol "$string" should be invertable');
}

invalidSymbol(String string) {
  Expect.throws(() => new Symbol(string),
                (e) => e is ArgumentError,
                'Invalid symbol "$string" should be rejected');
  Expect.throws(() => MirrorSystem.getSymbol(string),
                (e) => e is ArgumentError,
                'Invalid symbol "$string" should be rejected');
}

main() {
  ['%', '&', '*', '+', '-', '/', '<', '<<', '<=', '==', '>',
   '>=', '>>', '[]', '[]=', '^', 'unary-', '|', '~', '~/']
      .forEach(validSymbol);

  ['foo', '_bar', 'baz.quz', 'fisk1', 'hest2fisk', 'a.b.c.d.e',
   '\$', 'foo\$', 'bar\$bar']
      .forEach(validSymbol);

  ['6', '0foo', ',', 'S with M', '_invalid&private']
      .forEach(invalidSymbol);
}
