// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:js_ast/js_ast.dart';
import 'print_helper.dart';

void main() {
  final aPowB = testExpression('a ** b');

  testExpression('# ** c', aPowB, '(a ** b) ** c');
  testExpression('c ** #', aPowB, 'c ** a ** b');

  // Miniparser parses with incorrect association:
  testExpression('a ** b ** c', '(a ** b) ** c');

  testExpression('(a ** b) ** c', '(a ** b) ** c');
  testExpression('a ** (b ** c)', 'a ** b ** c');
  testExpression('a **= b');

  // `-a**b` is a JavaScript parse error. Parentheses are required to
  // disambiguate between `(-a)**b` and `-(a**b)`.

  testExpression('-(2 ** n)');

  testExpression('(-(2)) ** n', '(-2) ** n');
  testExpression('(-2) ** n', '(-2) ** n');

  final minus2 = js.number(-2);
  final negated2 = js('-#', js.number(2));

  testExpression('# ** x', minus2, '(-2) ** x');
  testExpression('# ** x', negated2, '(-2) ** x');

  testExpression('-(2 ** n)');
}
