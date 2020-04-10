// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';

const _desc = r'Avoid types as parameter names.';

const _details = r'''

**AVOID** using a parameter name that is the same as an existing type.

**BAD:**
```
m(f(int));
```

**GOOD:**
```
m(f(int v));
```

''';

class AvoidTypesAsParameterNames extends LintRule implements NodeLintRule {
  AvoidTypesAsParameterNames()
      : super(
            name: 'avoid_types_as_parameter_names',
            description: _desc,
            details: _details,
            group: Group.errors);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this, context);
    registry.addFormalParameterList(this, visitor);
    registry.addCatchClause(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitCatchClause(CatchClause node) {
    final parameter = node.exceptionParameter;
    if (parameter != null && _isTypeName(node, parameter)) {
      rule.reportLint(parameter);
    }
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    if (node.parent is GenericFunctionType) return;

    for (final parameter in node.parameters) {
      if (parameter.declaredElement.hasImplicitType &&
          _isTypeName(node, parameter.identifier)) {
        rule.reportLint(parameter.identifier);
      }
    }
  }

  bool _isTypeName(AstNode scope, SimpleIdentifier node) {
    final result = context.resolveNameInScope(node.name, false, scope);
    if (result.isRequestedName) {
      final element = result.element;
      return element is ClassElement || element is FunctionTypeAliasElement;
    }
    return false;
  }
}
