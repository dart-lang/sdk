// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart'
    show
        AstNode,
        AstVisitor,
        PrefixExpression,
        PrefixedIdentifier,
        PropertyAccess,
        SimpleIdentifier;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart' show Element;
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/ast.dart';

const _desc = r'Use `isNotEmpty` for Iterables and Maps.';

const _details = r'''

**PREFER** `x.isNotEmpty` to `!x.isEmpty` for `Iterable` and `Map` instances.

When testing whether an iterable or map is empty, prefer `isNotEmpty` over
`!isEmpty` to improve code readability.

**GOOD:**
```
if (todo.isNotEmpty) {
  sendResults(request, todo.isEmpty);
}
```

**BAD:**
```
if (!sources.isEmpty) {
  process(sources);
}
```

''';

class PreferIsNotEmpty extends LintRule {
  PreferIsNotEmpty()
      : super(
            name: 'prefer_is_not_empty',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;
  Visitor(this.rule);

  @override
  visitSimpleIdentifier(SimpleIdentifier identifier) {
    AstNode isEmptyAccess;
    SimpleIdentifier isEmptyIdentifier;

    AstNode parent = identifier.parent;
    if (parent is PropertyAccess) {
      isEmptyIdentifier = parent.propertyName;
      isEmptyAccess = parent;
    } else if (parent is PrefixedIdentifier) {
      isEmptyIdentifier = parent.identifier;
      isEmptyAccess = parent;
    }

    if (isEmptyIdentifier == null) {
      return;
    }

    // Should be "isEmpty".
    Element propertyElement = isEmptyIdentifier.bestElement;
    if (propertyElement == null || 'isEmpty' != propertyElement.name) {
      return;
    }
    // Should have "isNotEmpty".
    Element propertyTarget = propertyElement.enclosingElement;
    if (propertyTarget == null ||
        getChildren(propertyTarget, 'isNotEmpty').isEmpty) {
      return;
    }
    // Should be in PrefixExpression.
    if (isEmptyAccess.parent is! PrefixExpression) {
      return;
    }
    PrefixExpression prefixExpression =
        isEmptyAccess.parent as PrefixExpression;
    // Should be !
    if (prefixExpression.operator.type != TokenType.BANG) {
      return;
    }

    rule.reportLint(prefixExpression);
  }
}
