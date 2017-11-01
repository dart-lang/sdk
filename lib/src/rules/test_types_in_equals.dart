// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file

// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Test type arguments in operator ==(Object other).';

const _details = r'''

**DO** test type arguments in operator ==(Object other).

Not testing types so might result in null pointer exceptions which will be
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

class TestTypesInEquals extends LintRule {
  TestTypesInEquals()
      : super(
            name: 'test_types_in_equals',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  AstVisitor getVisitor() => new _Visitor(this);
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  visitAsExpression(AsExpression node) {
    MethodDeclaration declaration =
        node.getAncestor((n) => n is MethodDeclaration);
    if (!_isEqualsOverride(declaration) ||
        node.expression is! SimpleIdentifier) {
      return;
    }

    SimpleIdentifier identifier = node.expression;
    var parameters = declaration.parameters;
    String parameterName = parameters == null
        ? null
        : resolutionMap
            .parameterElementsForFormalParameterList(parameters)
            ?.first
            ?.name;
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
