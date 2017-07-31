// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const desc = 'Avoid using braces in interpolation when not needed.';

const details = r'''
**AVOID** using braces in interpolation when not needed.

If you're just interpolating a simple identifier, and it's not immediately
followed by more alphanumeric text, the `{}` can and should be omitted.

**GOOD:**
```dart
print("Hi, $name!");
```

**BAD:**
```dart
print("Hi, ${name}!");
```
''';

final RegExp identifierPart = new RegExp(r'^[a-zA-Z0-9_]');

bool isIdentifierPart(Token token) =>
    token is StringToken && token.lexeme.startsWith(identifierPart);

class UnnecessaryBraceInStringInterps extends LintRule {
  UnnecessaryBraceInStringInterps()
      : super(
            name: 'unnecessary_brace_in_string_interps',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  LintRule rule;
  Visitor(this.rule);

  @override
  visitStringInterpolation(StringInterpolation node) {
    var expressions = node.elements.where((e) => e is InterpolationExpression);
    for (InterpolationExpression expression in expressions) {
      if (expression.expression is SimpleIdentifier) {
        SimpleIdentifier identifier = expression.expression;
        Token bracket = expression.rightBracket;
        if (bracket != null &&
            !isIdentifierPart(bracket.next) &&
            !identifier.name.contains('\$')) {
          rule.reportLint(expression);
        }
      }
    }
  }
}
