// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Test type arguments in operator ==(Object other).';

const _details = r'''

**DO** test type arguments in operator ==(Object other).

Not testing types might result in null pointer exceptions which will be
unexpected for consumers of your class.

**GOOD:**
```
class Field {
}

class Good {
  final Field someField;

  Good(this.someField);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is Good &&
        this.someField == other.someField;
  }

  @override
  int get hashCode {
    return someField.hashCode;
  }
}
```

**BAD:**
```
class Field {
}

class Bad {
  final Field someField;

  Bad(this.someField);

  @override
  bool operator ==(Object other) {
    Bad otherBad = other as Bad; // LINT
    bool areEqual = otherBad != null && otherBad.someField == someField;
    return areEqual;
  }

  @override
  int get hashCode {
    return someField.hashCode;
  }
}
```

''';

class TestTypesInEquals extends LintRule implements NodeLintRule {
  TestTypesInEquals()
      : super(
            name: 'test_types_in_equals',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addAsExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitAsExpression(AsExpression node) {
    final declaration = node.thisOrAncestorOfType<MethodDeclaration>();
    if (!_isEqualsOverride(declaration) ||
        node.expression is! SimpleIdentifier) {
      return;
    }

    final identifier = node.expression as SimpleIdentifier;
    var parameters = declaration.parameters;
    final parameterName = parameters?.parameterElements?.first?.name;
    if (identifier.name == parameterName) {
      rule.reportLint(node);
    }
  }

  bool _isEqualsOverride(MethodDeclaration declaration) =>
      declaration != null &&
      declaration.isOperator &&
      declaration.name.name == '==' &&
      declaration.parameters?.parameterElements?.length == 1;
}
