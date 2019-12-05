// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

import '../analyzer.dart';
import '../util/dart_type_utilities.dart';

const _desc =
    r"Don't override a method to do a super method invocation with the same"
    r' parameters.';

const _details = r'''

**DON'T** override a method to do a super method invocation with same parameters.

**BAD:**
```
class A extends B {
  @override
  void foo() {
    super.foo();
  }
}
```

**GOOD:**
```
class A extends B {
  @override
  void foo() {
    doSomethingElse();
  }
}
```

It's valid to override a member in the following cases:

* if a type (return type or a parameter type) is not the exactly the same as the
super method,
* if the `covariant` keyword is added to one of the parameters,
* if documentation comments are present on the member,
* if the member has annotations other than `@override`.

`noSuchMethod` is a special method and is not checked by this rule.

''';

class UnnecessaryOverrides extends LintRule implements NodeLintRule {
  UnnecessaryOverrides()
      : super(
            name: 'unnecessary_overrides',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    final visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

abstract class _AbstractUnnecessaryOverrideVisitor extends SimpleAstVisitor {
  final LintRule rule;

  ExecutableElement inheritedMethod;
  MethodDeclaration declaration;

  _AbstractUnnecessaryOverrideVisitor(this.rule);

  ExecutableElement getInheritedElement(MethodDeclaration node);

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
    // noSuchMethod is mandatory to proxify
    if (node.name.name == 'noSuchMethod') return;

    // it's ok to override to have better documentation
    if (node.documentationComment != null) return;

    inheritedMethod = getInheritedElement(node);
    declaration = node;
    if (inheritedMethod != null && !_addsMetadata() && _haveSameDeclaration()) {
      node.body.accept(this);
    }
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    node.unParenthesized.accept(this);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    node.expression?.accept(this);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    rule.reportLint(declaration.name);
  }

  bool _addsMetadata() {
    for (var annotation in declaration.declaredElement.metadata) {
      if (!annotation.isOverride) {
        return true;
      }
    }
    return false;
  }

  bool _haveSameDeclaration() {
    if (declaration.declaredElement.returnType != inheritedMethod.returnType) {
      return false;
    }
    if (declaration.declaredElement.parameters.length !=
        inheritedMethod.parameters.length) {
      return false;
    }
    for (var i = 0; i < inheritedMethod.parameters.length; i++) {
      final superParam = inheritedMethod.parameters[i];
      final param = declaration.declaredElement.parameters[i];
      if (param.type != superParam.type) return false;
      if (param.name != superParam.name) return false;
      if (param.isCovariant != superParam.isCovariant) return false;
      if (!_sameKind(param, superParam)) return false;
      if (param.defaultValueCode != superParam.defaultValueCode) return false;
    }
    return true;
  }

  bool _sameKind(ParameterElement first, ParameterElement second) {
    if (first.isNotOptional) {
      return second.isNotOptional;
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
  _UnnecessaryGetterOverrideVisitor(LintRule rule) : super(rule);

  @override
  ExecutableElement getInheritedElement(MethodDeclaration node) =>
      DartTypeUtilities.lookUpInheritedConcreteGetter(node);

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.staticElement == inheritedMethod) {
      node.target?.accept(this);
    }
  }
}

class _UnnecessaryMethodOverrideVisitor
    extends _AbstractUnnecessaryOverrideVisitor {
  _UnnecessaryMethodOverrideVisitor(LintRule rule) : super(rule);

  @override
  ExecutableElement getInheritedElement(node) =>
      DartTypeUtilities.lookUpInheritedMethod(node);

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.staticElement == inheritedMethod &&
        DartTypeUtilities.matchesArgumentsWithParameters(
            node.argumentList.arguments, declaration.parameters.parameters)) {
      node.target?.accept(this);
    }
  }
}

class _UnnecessaryOperatorOverrideVisitor
    extends _AbstractUnnecessaryOverrideVisitor {
  _UnnecessaryOperatorOverrideVisitor(LintRule rule) : super(rule);

  @override
  ExecutableElement getInheritedElement(node) =>
      DartTypeUtilities.lookUpInheritedConcreteMethod(node);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final parameters = declaration.parameters.parameters;
    if (node.operator.type == declaration.name.token.type &&
        parameters.length == 1 &&
        parameters.first.identifier.staticElement ==
            DartTypeUtilities.getCanonicalElementFromIdentifier(
                node.rightOperand)) {
      final leftPart = node.leftOperand.unParenthesized;
      if (leftPart is SuperExpression) {
        visitSuperExpression(leftPart);
      }
    }
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    final parameters = declaration.parameters.parameters;
    if (node.operator.type == declaration.name.token.type &&
        parameters.isEmpty) {
      final operand = node.operand.unParenthesized;
      if (operand is SuperExpression) {
        visitSuperExpression(operand);
      }
    }
  }
}

class _UnnecessarySetterOverrideVisitor
    extends _AbstractUnnecessaryOverrideVisitor {
  _UnnecessarySetterOverrideVisitor(LintRule rule) : super(rule);

  @override
  ExecutableElement getInheritedElement(node) =>
      DartTypeUtilities.lookUpInheritedConcreteSetter(node);

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final parameters = declaration.parameters.parameters;
    if (parameters.length == 1 &&
        parameters.first.identifier.staticElement ==
            DartTypeUtilities.getCanonicalElementFromIdentifier(
                node.rightHandSide)) {
      final leftPart = node.leftHandSide.unParenthesized;
      if (leftPart is PropertyAccess) {
        _visitPropertyAccess(leftPart);
      }
    }
  }

  void _visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.staticElement == inheritedMethod) {
      node.target?.accept(this);
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
      final visitor = _UnnecessaryOperatorOverrideVisitor(rule);
      visitor.visitMethodDeclaration(node);
    } else if (node.isGetter) {
      final visitor = _UnnecessaryGetterOverrideVisitor(rule);
      visitor.visitMethodDeclaration(node);
    } else if (node.isSetter) {
      final visitor = _UnnecessarySetterOverrideVisitor(rule);
      visitor.visitMethodDeclaration(node);
    } else {
      final visitor = _UnnecessaryMethodOverrideVisitor(rule);
      visitor.visitMethodDeclaration(node);
    }
  }
}
