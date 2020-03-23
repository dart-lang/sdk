// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r'Avoid shadowing type parameters.';

const _details = r'''

**AVOID** shadowing type parameters.

**BAD:**
```
class A<T> {
  void fn<T>() {}
}
```

**GOOD:**
```
class A<T> {
  void fn<U>() {}
}
```

''';

class AvoidShadowingTypeParameters extends LintRule implements NodeLintRule {
  AvoidShadowingTypeParameters()
      : super(
            name: 'avoid_shadowing_type_parameters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addFunctionDeclarationStatement(this, visitor);
    registry.addGenericTypeAlias(this, visitor);
    registry.addMethodDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    var functionExpression = node.functionDeclaration.functionExpression;
    if (functionExpression.typeParameters == null) {
      return;
    }
    _checkAncestorParameters(functionExpression.typeParameters, node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    if (node.functionType?.typeParameters == null) {
      return;
    }
    _checkForShadowing(node.functionType.typeParameters, node.typeParameters);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.typeParameters == null) {
      return;
    }

    // Static methods have nothing above them to shadow.
    if (!node.isStatic) {
      _checkAncestorParameters(node.typeParameters, node);
    }
  }

  // Check the ancestors of [node] for type parameter shadowing.
  void _checkAncestorParameters(
      TypeParameterList typeParameters, AstNode node) {
    var parent = node.parent;

    while (parent != null) {
      if (parent is ClassOrMixinDeclaration) {
        _checkForShadowing(typeParameters, parent.typeParameters);
      } else if (parent is ExtensionDeclaration) {
        _checkForShadowing(typeParameters, parent.typeParameters);
      } else if (parent is MethodDeclaration) {
        _checkForShadowing(typeParameters, parent.typeParameters);
      } else if (parent is FunctionDeclaration) {
        _checkForShadowing(
            typeParameters, parent.functionExpression.typeParameters);
      }
      parent = parent.parent;
    }
  }

  // Check whether any of [typeParameters] shadow [ancestorTypeParameters].
  void _checkForShadowing(TypeParameterList typeParameters,
      TypeParameterList ancestorTypeParameters) {
    if (ancestorTypeParameters == null) {
      return;
    }

    var typeParameterIds = typeParameters.typeParameters.map((tp) => tp.name);
    var ancestorTypeParameterNames =
        ancestorTypeParameters.typeParameters.map((tp) => tp.name.name);
    var shadowingTypeParameters = typeParameterIds
        .where((tp) => ancestorTypeParameterNames.contains(tp.name));

    shadowingTypeParameters.forEach(rule.reportLint);
  }
}
