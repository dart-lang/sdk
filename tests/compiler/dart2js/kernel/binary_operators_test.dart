// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'helper.dart' show check;

main() {
  group('compile binary operators', () {
    test('plus on ints', () {
      return check('main() { return 1 + 2; }');
    });
    test('plus on strings', () {
      return check('main() { return "a" + "b"; }');
    });
    test('plus on non-constants', () {
      String code = '''
        foo() => 1;
        main() => foo() + foo();''';
      return check(code);
    });
    test('other arithmetic operators', () {
      return check('main() { return 1 + 2 * 3 - 4 / 5 % 6; }');
    });
  });
}
