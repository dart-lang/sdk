// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart'
    show PrefixExpression, PrefixedIdentifier, PropertyAccess, SimpleIdentifier;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../ast.dart';

const _desc = r'Use `isNotEmpty` for Iterables and Maps.';

const _details = r'''
**PREFER** `x.isNotEmpty` to `!x.isEmpty` for `Iterable` and `Map` instances.

When testing whether an iterable or map is empty, prefer `isNotEmpty` over
`!isEmpty` to improve code readability.

**BAD:**
```dart
if (!sources.isEmpty) {
  process(sources);
}
```

**GOOD:**
```dart
if (todo.isNotEmpty) {
  sendResults(request, todo.isEmpty);
}
```

''';

class PreferIsNotEmpty extends LintRule {
  static const LintCode code = LintCode('prefer_is_not_empty',
      "Use 'isNotEmpty' rather than negating the result of 'isEmpty'.",
      correctionMessage: "Try rewriting the expression to use 'isNotEmpty'.");

  PreferIsNotEmpty()
      : super(
            name: 'prefer_is_not_empty',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addPrefixExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitPrefixExpression(PrefixExpression node) {
    // Should be prefixed w/ a "!".
    var prefix = node.operator;
    if (prefix.type != TokenType.BANG) {
      return;
    }

    var expression = node.operand.unParenthesized;

    // Should be a property access or prefixed identifier.
    SimpleIdentifier? isEmptyIdentifier;
    if (expression is PropertyAccess) {
      isEmptyIdentifier = expression.propertyName;
    } else if (expression is PrefixedIdentifier) {
      isEmptyIdentifier = expression.identifier;
    }
    if (isEmptyIdentifier == null) {
      return;
    }

    // Element identifier should be "isEmpty".
    var propertyElement = isEmptyIdentifier.staticElement;
    if (propertyElement == null || 'isEmpty' != propertyElement.name) {
      return;
    }

    // Element should also support "isNotEmpty".
    var propertyTarget = propertyElement.enclosingElement;
    if (propertyTarget == null ||
        getChildren(propertyTarget, 'isNotEmpty').isEmpty) {
      return;
    }

    rule.reportLint(node);
  }
}
