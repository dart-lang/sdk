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
```dart
class A<T> {
  void fn<T>() {}
}
```

**GOOD:**
```dart
class A<T> {
  void fn<U>() {}
}
```

''';

class AvoidShadowingTypeParameters extends LintRule {
  static const LintCode code = LintCode('avoid_shadowing_type_parameters',
      "The type parameter '{0}' shadows a type parameter from the enclosing {1}.",
      correctionMessage: 'Try renaming one of the type parameters.');

  AvoidShadowingTypeParameters()
      : super(
            name: 'avoid_shadowing_type_parameters',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
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
    if (functionExpression.typeParameters != null) {
      _checkAncestorParameters(functionExpression.typeParameters, node);
    }
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    var typeParameters = node.functionType?.typeParameters;
    if (typeParameters != null) {
      _checkForShadowing(typeParameters, node.typeParameters, 'typedef');
    }
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
      TypeParameterList? typeParameters, AstNode node) {
    var parent = node.parent;

    while (parent != null) {
      if (parent is ClassDeclaration) {
        _checkForShadowing(typeParameters, parent.typeParameters, 'class');
      } else if (parent is EnumDeclaration) {
        _checkForShadowing(typeParameters, parent.typeParameters, 'enum');
      } else if (parent is ExtensionDeclaration) {
        _checkForShadowing(typeParameters, parent.typeParameters, 'extension');
      } else if (parent is ExtensionTypeDeclaration) {
        _checkForShadowing(
            typeParameters, parent.typeParameters, 'extension type');
      } else if (parent is MethodDeclaration) {
        _checkForShadowing(typeParameters, parent.typeParameters, 'method');
      } else if (parent is MixinDeclaration) {
        _checkForShadowing(typeParameters, parent.typeParameters, 'mixin');
      } else if (parent is FunctionDeclaration) {
        _checkForShadowing(typeParameters,
            parent.functionExpression.typeParameters, 'function');
      }
      parent = parent.parent;
    }
  }

  // Check whether any of [typeParameters] shadow [ancestorTypeParameters].
  void _checkForShadowing(TypeParameterList? typeParameters,
      TypeParameterList? ancestorTypeParameters, String ancestorKind) {
    if (typeParameters == null || ancestorTypeParameters == null) {
      return;
    }

    var ancestorTypeParameterNames = ancestorTypeParameters.typeParameters
        .map((tp) => tp.name.lexeme)
        .toSet();

    for (var parameter in typeParameters.typeParameters) {
      if (ancestorTypeParameterNames.contains(parameter.name.lexeme)) {
        rule.reportLint(parameter,
            arguments: [parameter.name.lexeme, ancestorKind]);
      }
    }
  }
}
