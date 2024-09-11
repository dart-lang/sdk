// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r'Avoid using braces in interpolation when not needed.';

const _details = r'''
**AVOID** using braces in interpolation when not needed.

If you're just interpolating a simple identifier, and it's not immediately
followed by more alphanumeric text, the `{}` can and should be omitted.

**BAD:**
```dart
print("Hi, ${name}!");
```

**GOOD:**
```dart
print("Hi, $name!");
```

''';

final RegExp identifierPart = RegExp('[a-zA-Z0-9_]');

bool isIdentifierPart(Token? token) =>
    token is StringToken && token.lexeme.startsWith(identifierPart);

class UnnecessaryBraceInStringInterps extends LintRule {
  UnnecessaryBraceInStringInterps()
      : super(
          name: 'unnecessary_brace_in_string_interps',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.unnecessary_brace_in_string_interps;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addStringInterpolation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitStringInterpolation(StringInterpolation node) {
    var expressions = node.elements.whereType<InterpolationExpression>();
    for (var expression in expressions) {
      var exp = expression.expression;
      if (exp is SimpleIdentifier) {
        var identifier = exp;
        if (!identifier.name.contains('\$')) {
          _check(expression);
        }
      } else if (exp is ThisExpression) {
        _check(expression);
      }
    }
  }

  void _check(InterpolationExpression expression) {
    var bracket = expression.rightBracket;
    if (bracket != null && !isIdentifierPart(bracket.next)) {
      rule.reportLint(expression);
    }
  }
}
