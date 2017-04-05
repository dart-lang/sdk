// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.avoid_annotating_types_on_function_expressions;

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';

const _desc = r'Avoid annotating types on function expression parameters.';

const _details = r'''

**AVOID** annotating types on function expressions.

**BAD:**
```
var names = people.map((Person person) => person.name);
```

**GOOD:**
```
var names = people.map((person) => person.name);
```

''';

NormalFormalParameter _getNormalFormalParameter(FormalParameter node) {
  if (node is DefaultFormalParameter) {
    return node.parameter;
  }
  return node;
}

bool _hasNonDynamicType(NormalFormalParameter parameter) {
  if (parameter is SimpleFormalParameter) {
    return parameter.type != null && parameter.type.name.name != 'dynamic';
  }
  return true;
}

class AvoidTypesOnClosureParameters extends LintRule {
  _Visitor _visitor;
  AvoidTypesOnClosureParameters()
      : super(
            name: 'avoid_types_on_closure_parameters',
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
  visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      return;
    }
    final nonDynamicParameters = node.parameters.parameters
        .map(_getNormalFormalParameter)
        .where(_hasNonDynamicType);
    if (nonDynamicParameters.isNotEmpty) {
      rule.reportLint(nonDynamicParameters.first);
    }
  }
}
