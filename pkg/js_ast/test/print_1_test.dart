// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:js_ast/js_ast.dart';
import 'print_helper.dart';

void main() {
  // Basic precedence.
  final aPlus1 = testExpression('a + 1');
  final bTimes2 = testExpression('b * 2');

  Expect.type<Binary>(aPlus1);
  Expect.type<Binary>(bTimes2);

  testExpression('# + x', aPlus1, 'a + 1 + x');
  testExpression('x + #', aPlus1, 'x + (a + 1)');
  testExpression('# * x', aPlus1, '(a + 1) * x');
  testExpression('x * #', aPlus1, 'x * (a + 1)');

  testExpression('# + x', bTimes2, 'b * 2 + x');
  testExpression('x + #', bTimes2, 'x + b * 2');
  testExpression('# * x', bTimes2, 'b * 2 * x');
  testExpression('x * #', bTimes2, 'x * (b * 2)');

  testExpression('# + #', [aPlus1, aPlus1], 'a + 1 + (a + 1)');
  testExpression('# + #', [bTimes2, bTimes2], 'b * 2 + b * 2');
  testExpression('# * #', [aPlus1, aPlus1], '(a + 1) * (a + 1)');
  testExpression('# * #', [bTimes2, bTimes2], 'b * 2 * (b * 2)');
}
