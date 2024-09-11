// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../linter_lint_codes.dart';
import '../util/dart_type_utilities.dart';

const _desc =
    r"Don't override a method to do a super method invocation with the same"
    r' parameters.';

const _details = r'''
**DON'T** override a method to do a super method invocation with same parameters.

**BAD:**
```dart
class A extends B {
  @override
  void foo() {
    super.foo();
  }
}
```

**GOOD:**
```dart
class A extends B {
  @override
  void foo() {
    doSomethingElse();
  }
}
```

It's valid to override a member in the following cases:

* if a type (return type or a parameter type) is not the exactly the same as the
  super member,
* if the `covariant` keyword is added to one of the parameters,
* if documentation comments are present on the member,
* if the member has annotations other than `@override`,
* if the member is not annotated with `@protected`, and the super member is.

`noSuchMethod` is a special method and is not checked by this rule.

''';

class UnnecessaryOverrides extends LintRule {
  UnnecessaryOverrides()
      : super(
          name: 'unnecessary_overrides',
          description: _desc,
          details: _details,
        );

  @override
  LintCode get lintCode => LinterLintCode.unnecessary_overrides;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

abstract class _AbstractUnnecessaryOverrideVisitor extends SimpleAstVisitor {
  final LintRule rule;

  /// If [declaration] is an inherited member of interest, then this is set in
  /// [visitMethodDeclaration].
  late ExecutableElement _inheritedMethod;
  late MethodDeclaration declaration;

  _AbstractUnnecessaryOverrideVisitor(this.rule);

  ExecutableElement? getInheritedElement(MethodDeclaration node);

  @override
  void visitBlock(Block node) {
    if (node.statements.length == 1) {
      node.statements.first.accept(this);
    }
  }

  @override
  void visitBlockFunctionBody(BlockFunctionBody node) {
    visitBlock(node.block);
  }

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    node.expression.accept(this);
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    node.expression.accept(this);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // 'noSuchMethod' is mandatory to proxify.
    if (node.name.lexeme == 'noSuchMethod') return;

    // It's ok to override to have better documentation.
    if (node.documentationComment != null) return;

    var inheritedMethod = getInheritedElement(node);
    if (inheritedMethod == null) return;
    _inheritedMethod = inheritedMethod;
    declaration = node;

    // It's ok to override to add annotations.
    if (_addsMetadata()) return;

    // It's ok to override to change the signature.
    if (!_haveSameDeclaration()) return;

    // It's ok to override to make a `@protected` method public.
    if (_makesPublicFromProtected()) return;

    node.body.accept(this);
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    node.unParenthesized.accept(this);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (node.beginToken.precedingComments != null) return;
    node.expression?.accept(this);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    if (node.beginToken.precedingComments != null) return;
    rule.reportLintForToken(declaration.name);
  }

  /// Returns whether [declaration] is annotated with any metadata (other than
  /// `@override` or `@Override`).
  bool _addsMetadata() {
    var metadata = declaration.declaredElement?.metadata;
    if (metadata != null) {
      for (var annotation in metadata) {
        if (annotation.isOverride) continue;
        if (annotation.isProtected && _inheritedMethod.hasProtected) continue;

        // Any other annotation implies a meaningful override.
        return true;
      }
    }
    return false;
  }

  bool _haveSameDeclaration() {
    var declaredElement = declaration.declaredElement;
    if (declaredElement == null) {
      return false;
    }
    if (declaredElement.returnType != _inheritedMethod.returnType) {
      return false;
    }
    if (declaredElement.parameters.length !=
        _inheritedMethod.parameters.length) {
      return false;
    }
    for (var i = 0; i < _inheritedMethod.parameters.length; i++) {
      var superParam = _inheritedMethod.parameters[i];
      var param = declaredElement.parameters[i];
      if (param.type != superParam.type) return false;
      if (param.name != superParam.name) return false;
      if (param.isCovariant != superParam.isCovariant) return false;
      if (!_sameKind(param, superParam)) return false;
      if (param.defaultValueCode != superParam.defaultValueCode) return false;
    }
    return true;
  }

  /// Returns true if [_inheritedMethod] is `@protected` and [declaration] is
  /// not `@protected`, and false otherwise.
  ///
  /// This indicates that [_inheritedMethod] may have been overridden in order
  /// to expand its visibility.
  bool _makesPublicFromProtected() {
    var declaredElement = declaration.declaredElement;
    if (declaredElement == null) return false;
    if (declaredElement.hasProtected) {
      return false;
    }
    return _inheritedMethod.hasProtected;
  }

  bool _sameKind(ParameterElement first, ParameterElement second) {
    if (first.isRequired) {
      return second.isRequired;
    } else if (first.isOptionalPositional) {
      return second.isOptionalPositional;
    } else if (first.isNamed) {
      return second.isNamed;
    }
    throw ArgumentError('Unhandled kind of parameter.');
  }
}

class _UnnecessaryGetterOverrideVisitor
    extends _AbstractUnnecessaryOverrideVisitor {
  _UnnecessaryGetterOverrideVisitor(super.rule);

  @override
  ExecutableElement? getInheritedElement(MethodDeclaration node) {
    var element = node.declaredElement;
    if (element == null) return null;
    var enclosingElement = element.enclosingElement3;
    if (enclosingElement is! InterfaceElement) return null;
    return enclosingElement.thisType.lookUpGetter2(
      element.name,
      element.library,
      concrete: true,
      inherited: true,
    );
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == _inheritedMethod.name) {
      node.target?.accept(this);
    }
  }
}

class _UnnecessaryMethodOverrideVisitor
    extends _AbstractUnnecessaryOverrideVisitor {
  _UnnecessaryMethodOverrideVisitor(super.rule);

  @override
  ExecutableElement? getInheritedElement(node) {
    var element = node.declaredElement;
    if (element == null) return null;

    var enclosingElement = element.enclosingElement3;
    if (enclosingElement is! InterfaceElement) return null;

    var augmented = enclosingElement.augmented;
    return augmented.declaration.thisType.lookUpMethod2(
      node.name.lexeme,
      element.library,
      concrete: true,
      inherited: true,
    );
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    var declarationParameters = declaration.parameters;
    if (declarationParameters != null &&
        node.methodName.name == _inheritedMethod.name &&
        argumentsMatchParameters(
            node.argumentList.arguments, declarationParameters.parameters)) {
      node.target?.accept(this);
    }
  }
}

class _UnnecessaryOperatorOverrideVisitor
    extends _AbstractUnnecessaryOverrideVisitor {
  _UnnecessaryOperatorOverrideVisitor(super.rule);

  @override
  ExecutableElement? getInheritedElement(node) {
    var element = node.declaredElement;
    if (element == null) return null;
    var enclosingElement = element.enclosingElement3;
    if (enclosingElement is! InterfaceElement) return null;
    return enclosingElement.thisType.lookUpMethod2(
      element.name,
      element.library,
      concrete: true,
      inherited: true,
    );
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    var parameters = declaration.parameters?.parameters;
    if (node.operator.type == declaration.name.type &&
        parameters != null &&
        parameters.length == 1 &&
        parameters.first.declaredElement ==
            node.rightOperand.canonicalElement) {
      var leftPart = node.leftOperand.unParenthesized;
      if (leftPart is SuperExpression) {
        visitSuperExpression(leftPart);
      }
    }
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    var parameters = declaration.parameters?.parameters;
    if (parameters != null &&
        node.operator.type == declaration.name.type &&
        parameters.isEmpty) {
      var operand = node.operand.unParenthesized;
      if (operand is SuperExpression) {
        visitSuperExpression(operand);
      }
    }
  }
}

class _UnnecessarySetterOverrideVisitor
    extends _AbstractUnnecessaryOverrideVisitor {
  _UnnecessarySetterOverrideVisitor(super.rule);

  @override
  ExecutableElement? getInheritedElement(node) {
    var element = node.declaredElement;
    if (element == null) return null;
    var enclosingElement = element.enclosingElement3;
    if (enclosingElement is! InterfaceElement) return null;
    return enclosingElement.thisType.lookUpSetter2(
      node.name.lexeme,
      element.library,
      concrete: true,
      inherited: true,
    );
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    var parameters = declaration.parameters?.parameters;
    if (parameters != null &&
        parameters.length == 1 &&
        parameters.first.declaredElement ==
            node.rightHandSide.canonicalElement) {
      var leftPart = node.leftHandSide.unParenthesized;
      if (leftPart is PropertyAccess) {
        if (node.writeElement?.name == _inheritedMethod.name) {
          leftPart.target?.accept(this);
        }
      }
    }
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    if (node.isStatic) {
      return;
    }
    if (node.operatorKeyword != null) {
      var visitor = _UnnecessaryOperatorOverrideVisitor(rule);
      visitor.visitMethodDeclaration(node);
    } else if (node.isGetter) {
      var visitor = _UnnecessaryGetterOverrideVisitor(rule);
      visitor.visitMethodDeclaration(node);
    } else if (node.isSetter) {
      var visitor = _UnnecessarySetterOverrideVisitor(rule);
      visitor.visitMethodDeclaration(node);
    } else {
      var visitor = _UnnecessaryMethodOverrideVisitor(rule);
      visitor.visitMethodDeclaration(node);
    }
  }
}
