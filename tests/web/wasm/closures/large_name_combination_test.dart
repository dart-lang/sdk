// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  final l = <dynamic>['a', 1, foo];
  final closure = l[int.parse('2')];

  final sb = StringBuffer();

  Expect.equals(foo(), closure());

  Expect.equals(foo(a0: 0), closure(a0: 0));
  Expect.equals(foo(a1: 1), closure(a1: 1));
  Expect.equals(foo(a2: 2), closure(a2: 2));
  Expect.equals(foo(a3: 3), closure(a3: 3));
  Expect.equals(foo(a4: 4), closure(a4: 4));
  Expect.equals(foo(a5: 5), closure(a5: 5));
  Expect.equals(foo(a6: 6), closure(a6: 6));
  Expect.equals(foo(a7: 7), closure(a7: 7));
  Expect.equals(foo(a8: 8), closure(a8: 8));
  Expect.equals(foo(a9: 9), closure(a9: 9));
  Expect.equals(foo(a10: 10), closure(a10: 10));
  Expect.equals(foo(a11: 11), closure(a11: 11));
  Expect.equals(foo(a12: 12), closure(a12: 12));
  Expect.equals(foo(a13: 13), closure(a13: 13));
  Expect.equals(foo(a14: 14), closure(a14: 14));
  Expect.equals(foo(a15: 15), closure(a15: 15));

  Expect.equals(foo(a0: 0, a1: 1), closure(a0: 0, a1: 1));
  Expect.equals(foo(a2: 2, a3: 3), closure(a2: 2, a3: 3));
  Expect.equals(foo(a4: 4, a5: 5), closure(a4: 4, a5: 5));
  Expect.equals(foo(a6: 6, a7: 7), closure(a6: 6, a7: 7));
  Expect.equals(foo(a8: 8, a9: 9), closure(a8: 8, a9: 9));
  Expect.equals(foo(a10: 10, a11: 11), closure(a10: 10, a11: 11));
  Expect.equals(foo(a12: 12, a13: 13), closure(a12: 12, a13: 13));
  Expect.equals(foo(a14: 14, a15: 15), closure(a14: 14, a15: 15));

  Expect.equals(
    foo(a0: 0, a1: 1, a2: 2, a3: 3),
    closure(a0: 0, a1: 1, a2: 2, a3: 3),
  );
  Expect.equals(
    foo(a4: 4, a5: 5, a6: 6, a7: 7),
    closure(a4: 4, a5: 5, a6: 6, a7: 7),
  );
  Expect.equals(
    foo(a8: 8, a9: 9, a10: 10, a11: 11),
    closure(a8: 8, a9: 9, a10: 10, a11: 11),
  );
  Expect.equals(
    foo(a12: 12, a13: 13, a14: 14, a15: 15),
    closure(a12: 12, a13: 13, a14: 14, a15: 15),
  );

  Expect.equals(
    foo(a0: 0, a1: 1, a2: 2, a3: 3, a4: 4, a5: 5, a6: 6, a7: 7),
    closure(a0: 0, a1: 1, a2: 2, a3: 3, a4: 4, a5: 5, a6: 6, a7: 7),
  );
  Expect.equals(
    foo(a8: 8, a9: 9, a10: 10, a11: 11, a12: 12, a13: 13, a14: 14, a15: 15),
    closure(a8: 8, a9: 9, a10: 10, a11: 11, a12: 12, a13: 13, a14: 14, a15: 15),
  );

  Expect.equals(
    foo(
      a0: 0,
      a1: 1,
      a2: 2,
      a3: 3,
      a4: 4,
      a5: 5,
      a6: 6,
      a7: 7,
      a8: 8,
      a9: 9,
      a10: 10,
      a11: 11,
      a12: 12,
      a13: 13,
      a14: 14,
      a15: 15,
    ),
    closure(
      a0: 0,
      a1: 1,
      a2: 2,
      a3: 3,
      a4: 4,
      a5: 5,
      a6: 6,
      a7: 7,
      a8: 8,
      a9: 9,
      a10: 10,
      a11: 11,
      a12: 12,
      a13: 13,
      a14: 14,
      a15: 15,
    ),
  );
}

String foo({
  a0,
  a1,
  a2,
  a3,
  a4,
  a5,
  a6,
  a7,
  a8,
  a9,
  a10,
  a11,
  a12,
  a13,
  a14,
  a15,
}) => '$a0 $a1 $a2 $a3 $a4 $a5 $a6 $a7 $a8 $a9 $a10 $a11 $a12 $a13 $a14 $a15';
