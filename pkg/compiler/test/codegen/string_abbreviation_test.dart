// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:expect/expect.dart';
import 'package:compiler/src/js_backend/string_abbreviation.dart';

void test(List<String> inputs, List<String> expected, {int minLength = 6}) {
  Expect.listEquals(
      expected, abbreviateToIdentifiers(inputs, minLength: minLength));
}

void main() {
  // No strings yields an empty pool.
  test([], []);

  // Results identical stretches compressed-out.
  test(
    [
      'Greetings Bob Smith',
      'Great work!',
      'Greetings Alice',
      'Greetings Bob Henry',
    ],
    [
      'GreetiBS',
      'Great_',
      'GreetiA',
      'GreetiBH',
    ],
  );

  test(
    [
      'Greetings Bob Smith',
      'Great work!',
      'Greetings Alice',
      'Greetings Bob Henry',
    ],
    [
      'GeBS',
      'Ga',
      'GeA',
      'GeBH',
    ],
    minLength: 1,
  );

  // Non-identifiers are replaced with '_' if that is unambiguous.
  test(
    ['!pingpong', 'xylograph'],
    ['_pingp', 'xylogr'],
  );

  test(['\u1234\xff'], ['__']);
  test(['\u1234\xff', 'smile'], ['__', 'smile']);

  test(
    ['a*b+c', '(x,y)', 'a*c-e', '(x,z)'],
    ['a_b_c', '_x_y_', 'a_c_e', '_x_z_'],
  );

  // Multiple discriminating non-identifier characters are replaced with an
  // escape, which causes a potentially ambiguous non-escape to be escaped.
  test(
    ['a xylograph', 'a !pingpong', 'a %percent'],
    ['a_x78ylo', 'a_x21pin', 'a_x25per'],
  );

  test(
    ['a\u1234z', 'auz'],
    ['a_z', 'auz'],
  );
  test(
    ['a\u1234z', 'auz'],
    ['a_', 'au'],
    minLength: 1,
  );

  test(
    ['a\u1234z', 'auz', 'a&z'],
    ['au1234z', 'ax75z', 'ax26z'],
  );
  test(
    ['a\u1234z', 'auz', 'a&z'],
    ['au1234', 'ax75', 'ax26'],
    minLength: 1,
  );

  test(
    ['a\u1234z', 'auz', 'a&z', 'a\u2345z'],
    ['au1234z', 'ax75z', 'ax26z', 'au2345z'],
  );
  test(
    ['a\u1234z', 'auz', 'a&z', 'a\u2345z'],
    ['au1234', 'ax75', 'ax26', 'au2345'],
    minLength: 1,
  );

  test(
    ['a\u1234z', 'auz', 'a&z', 'a\u2345z', 'axe'],
    ['au1234z', 'ax75z', 'ax26z', 'au2345z', 'ax78e'],
  );
  test(
    ['a\u1234z', 'auz', 'a&z', 'a\u2345z', 'axe'],
    ['au1234', 'ax75', 'ax26', 'au2345', 'ax78'],
    minLength: 1,
  );
}
