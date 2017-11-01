// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Use adjacent strings to concatenate string literals.';

const _details = r'''

**DO** use adjacent strings to concatenate string literals.

**BAD:**
```
raiseAlarm(
    'ERROR: Parts of the spaceship are on fire. Other ' +
    'parts are overrun by martians. Unclear which are which.');
```

**GOOD:**
```
raiseAlarm(
    'ERROR: Parts of the spaceship are on fire. Other '
    'parts are overrun by martians. Unclear which are which.');
```

''';

class PreferAdjacentStringConcatenation extends LintRule {
  _Visitor _visitor;
  PreferAdjacentStringConcatenation()
      : super(
            name: 'prefer_adjacent_string_concatenation',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type.lexeme == '+' &&
        node.leftOperand is StringLiteral &&
        node.rightOperand is StringLiteral) {
      rule.reportLintForToken(node.operator);
    }
  }
}
