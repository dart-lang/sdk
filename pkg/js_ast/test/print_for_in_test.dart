// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'print_helper.dart';

void main() {
  // The mini-parser does not recognize for-in statements, mis-parsing them as for-statements.
  testStatement(
    'for(a in b; a in b; a in b);',
    'for ((a in b); a in b; a in b)\n  ;',
  );

  final aInB = testExpression('a in b');

  testStatement(
    'for(#;#;#);',
    [aInB, aInB, aInB],
    'for ((a in b); a in b; a in b)\n  ;',
  );

  testStatement(
    'for(var v = (# || #);;);',
    [aInB, aInB],
    'for (var v = (a in b) || (a in b);;)\n  ;',
  );

  testStatement(
    'for (u = (a + 1) * (b in z);;);',
    'for (u = (a + 1) * (b in z);;)\n  ;',
  );

  testStatement(
    'for (u = (a + 1) * #;;);',
    aInB,
    'for (u = (a + 1) * (a in b);;)\n  ;',
  );

  testStatement(
    'for (u = (1 + a) * 2, v = 1 || (b in z) || 2;;);',
    'for (u = (1 + a) * 2, v = 1 || (b in z) || 2;;)\n  ;',
  );

  testStatement(
    'for (var v in x);',
    'for (var v in x)\n  ;',
  );
}
