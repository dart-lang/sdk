// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.always_use_required_for_non_null_named_parameter;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart' show AstVisitor, TypedLiteral;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';

const desc = 'Use @required.';

const details = '''
**DO** specify `@required` on named parameter without default value on which an
assert(param != null) is done.

**GOOD:**
```
m1({@required a}) {
  assert(a != null);
}

m2({a: 1}) {
  assert(a != null);
}
```

**BAD:**
```
m1({a}) {
  assert(a != null);
}
```

NOTE: Only asserts at the start of the bodies will be taken into account.
''';

/// The name of `meta` library, used to define analysis annotations.
String _META_LIB_NAME = "meta";

/// The name of the top-level variable used to mark a required named parameter.
String _REQUIRED_VAR_NAME = "required";

bool _isRequired(Element element) =>
    element is PropertyAccessorElement &&
    element.name == _REQUIRED_VAR_NAME &&
    element.library?.name == _META_LIB_NAME;

class AlwaysUseRequiredForNonNullNamedParameter extends LintRule {
  AlwaysUseRequiredForNonNullNamedParameter()
      : super(
            name: 'always_use_required_for_non_null_named_parameter',
            description: desc,
            details: details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;

  Visitor(this.rule);

  void checkLiteral(TypedLiteral literal) {
    if (literal.typeArguments == null) {
      rule.reportLintForToken(literal.beginToken);
    }
  }

  @override
  visitFormalParameterList(FormalParameterList node) {
    final namedParametersWithoutDefault = node.parameters
        .where((p) => p.kind == ParameterKind.NAMED)
        .map((p) => p as DefaultFormalParameter)
        .where((p) => p.defaultValue == null);
    for (final param in namedParametersWithoutDefault) {
      if (param.metadata.any((a) => _isRequired(a.element))) continue;

      final parent = param.parent.parent;
      if (parent is FunctionExpression) {
        _checkBody(param, parent.body);
      } else if (parent is ConstructorDeclaration) {
        _checkBody(param, parent.body);
      } else if (parent is MethodDeclaration) {
        _checkBody(param, parent.body);
      }
    }
  }

  _checkBody(DefaultFormalParameter param, FunctionBody body) {
    if (body is BlockFunctionBody) {
      final hasNotNullAssert = body.block.childEntities
          .skip(1) // the first `{`
          .takeWhile((e) => e is AssertStatement)
          .any((e) => _isAssertNotNull(e, param.identifier));
      if (hasNotNullAssert) {
        rule.reportLintForToken(param.identifier.beginToken);
      }
    }
  }

  _isAssertNotNull(AssertStatement node, SimpleIdentifier identifier) {
    final expression = node.condition.unParenthesized;
    return expression is BinaryExpression &&
        expression.leftOperand is SimpleIdentifier &&
        (expression.leftOperand as SimpleIdentifier).name == identifier.name &&
        expression.operator.type == TokenType.BANG_EQ &&
        expression.rightOperand is NullLiteral;
  }
}
