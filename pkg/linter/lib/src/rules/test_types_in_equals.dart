// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';
import '../linter_lint_codes.dart';

const _desc = r'Test type of argument in `operator ==(Object other)`.';

const _details = r'''
**DO** test type of argument in `operator ==(Object other)`.

Not testing the type might result in runtime type errors which will be
unexpected for consumers of your class.

**BAD:**
```dart
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

**GOOD:**
```dart
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

''';

class TestTypesInEquals extends LintRule {
  TestTypesInEquals()
      : super(
          name: 'test_types_in_equals',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.test_types_in_equals;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addAsExpression(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitAsExpression(AsExpression node) {
    var declaration = node.thisOrAncestorOfType<MethodDeclaration>();
    var expression = node.expression;
    if (!_isEqualsOverride(declaration) || expression is! SimpleIdentifier) {
      return;
    }

    var parameters = declaration?.parameters;
    var parameterName = parameters?.parameterElements.first?.name;
    if (expression.name == parameterName) {
      var typeName = _getTypeName(declaration!);
      rule.reportLint(node, arguments: [typeName]);
    }
  }

  String _getTypeName(MethodDeclaration method) {
    var parent = method.parent;
    if (parent is ClassDeclaration) {
      return parent.name.lexeme;
    } else if (parent is EnumDeclaration) {
      return parent.name.lexeme;
    } else if (parent is MixinDeclaration) {
      return parent.name.lexeme;
    } else if (parent is ExtensionDeclaration) {
      if (parent.onClause case var onClause?) {
        return onClause.extendedType.toSource();
      }
    }
    return 'unknown';
  }

  bool _isEqualsOverride(MethodDeclaration? declaration) =>
      declaration != null &&
      declaration.isOperator &&
      declaration.name.lexeme == '==' &&
      declaration.parameters?.parameterElements.length == 1;
}
