// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r'Avoid positional boolean parameters.';

const _details = r'''

**AVOID** positional boolean parameters.

**BAD:**
```
new Task(true);
new Task(false);
new ListBox(false, true, true);
new Button(false);
```

**GOOD:**
```
new Task.oneShot();
new Task.repeating();
new ListBox(scroll: true, showScrollbars: true);
new Button(ButtonState.enabled);
```

''';

bool _hasInheritedMethod(MethodDeclaration node) =>
    DartTypeUtilities.lookUpInheritedMethod(node) != null;

bool _isNamedParameter(FormalParameter node) =>
    node.kind == ParameterKind.NAMED;

class AvoidPositionalBooleanParameters extends LintRule {
  _Visitor _visitor;
  AvoidPositionalBooleanParameters()
      : super(
            name: 'avoid_positional_boolean_parameters',
            description: _desc,
            details: _details,
            group: Group.style,
            maturity: Maturity.experimental) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  visitConstructorDeclaration(ConstructorDeclaration node) {
    if (!node.element.isPrivate) {
      final parametersToLint =
          node.parameters?.parameters?.where(_isFormalParameterToLint);
      if (parametersToLint?.isNotEmpty == true) {
        rule.reportLint(parametersToLint.first);
      }
    }
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    if (!node.element.isPrivate) {
      final parametersToLint = node.functionExpression.parameters?.parameters
          ?.where(_isFormalParameterToLint);
      if (parametersToLint?.isNotEmpty == true) {
        rule.reportLint(parametersToLint.first);
      }
    }
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    if (!node.isSetter &&
        !node.element.isPrivate &&
        !_hasInheritedMethod(node)) {
      final parametersToLint =
          node.parameters?.parameters?.where(_isFormalParameterToLint);
      if (parametersToLint?.isNotEmpty == true) {
        rule.reportLint(parametersToLint.first);
      }
    }
  }

  bool _isFormalParameterToLint(FormalParameter node) =>
      DartTypeUtilities.implementsInterface(
          node.identifier.bestType, 'bool', 'dart.core') &&
      !_isNamedParameter(node);
}
