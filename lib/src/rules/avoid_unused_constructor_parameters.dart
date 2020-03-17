// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../utils.dart';

const _desc = r'Avoid defining unused parameters in constructors.';

const _details = r'''

**AVOID** defining unused parameters in constructors.

**BAD:**
```
class BadOne {
  BadOne(int unusedParameter, [String unusedPositional]);
}

class BadTwo {
  int c;

  BadTwo(int a, int b, int x) {
    c = a + b;
  }
}
```

''';

class AvoidUnusedConstructorParameters extends LintRule
    implements NodeLintRule {
  AvoidUnusedConstructorParameters()
      : super(
            name: 'avoid_unused_constructor_parameters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _ConstructorVisitor extends RecursiveAstVisitor {
  final LintRule rule;
  final ConstructorDeclaration element;
  final Set<FormalParameter> unusedParameters;

  _ConstructorVisitor(this.rule, this.element)
      : unusedParameters = element.parameters.parameters.where((p) {
          final element = p.declaredElement;
          return element is! FieldFormalParameterElement &&
              !element.hasDeprecated &&
              !isJustUnderscores(element.name);
        }).toSet();

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    unusedParameters
        .removeWhere((p) => node.staticElement == p.declaredElement);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.redirectedConstructor != null) return;
    if (node.externalKeyword != null) return;

    final _constructorVisitor = _ConstructorVisitor(rule, node);
    node?.body?.visitChildren(_constructorVisitor);
    node?.initializers?.forEach((i) => i.visitChildren(_constructorVisitor));

    _constructorVisitor.unusedParameters.forEach(rule.reportLint);
  }
}
