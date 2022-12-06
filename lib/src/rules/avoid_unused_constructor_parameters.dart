// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../util/ascii_utils.dart';

const _desc = r'Avoid defining unused parameters in constructors.';

const _details = r'''
**AVOID** defining unused parameters in constructors.

**BAD:**
```dart
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

class AvoidUnusedConstructorParameters extends LintRule {
  static const LintCode code = LintCode('avoid_unused_constructor_parameters',
      "The parameter '{0}' is not used in the constructor.",
      correctionMessage: 'Try using the parameter or removing it.');

  AvoidUnusedConstructorParameters()
      : super(
            name: 'avoid_unused_constructor_parameters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
  }
}

class _ConstructorVisitor extends RecursiveAstVisitor {
  final ConstructorDeclaration element;
  final Set<FormalParameter> unusedParameters;

  _ConstructorVisitor(this.element)
      : unusedParameters = element.parameters.parameters.where((p) {
          var element = p.declaredElement;
          return element != null &&
              element is! FieldFormalParameterElement &&
              element is! SuperFormalParameterElement &&
              !element.hasDeprecated &&
              !element.name.isJustUnderscores;
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

    var constructorVisitor = _ConstructorVisitor(node);
    node.body.visitChildren(constructorVisitor);
    for (var i in node.initializers) {
      i.visitChildren(constructorVisitor);
    }

    for (var parameter in constructorVisitor.unusedParameters) {
      rule.reportLint(parameter, arguments: [parameter.name!.lexeme]);
    }
  }
}
