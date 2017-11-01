// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc =
    r"Don't override a method to do a super method invocation with the same"
    r" parameters.";

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

It's valid to override method for the following cases:

* if a type (return type or a parameter type) is not the exactly the same as the
super method,
* if `covariant` keyword is added to one of the parameter,
* if documentation comments are present on the method.

`noSuchMethod` is a special method and is not checked by this rule.

''';

class UnnecessaryOverrides extends LintRule {
  _Visitor _visitor;
  UnnecessaryOverrides()
      : super(
            name: 'unnecessary_overrides',
            description: _desc,
            details: _details,
            group: Group.style) {
    _visitor = new _Visitor(this);
  }

  @override
  AstVisitor getVisitor() => _visitor;
}

abstract class _AbstractUnnecessaryOverrideVisitor extends SimpleAstVisitor {
  LintRule rule;
  ExecutableElement inheritedMethod;
  MethodDeclaration declaration;

  _AbstractUnnecessaryOverrideVisitor(this.rule);

  ExecutableElement getInheritedElement(node);

  @override
  visitBlock(Block node) {
    if (node.statements.length == 1) {
      node.statements.first.accept(this);
    }
  }

  @override
  visitBlockFunctionBody(BlockFunctionBody node) {
    visitBlock(node.block);
  }

  @override
  visitExpressionFunctionBody(ExpressionFunctionBody node) {
    node.expression.accept(this);
  }

  @override
  visitExpressionStatement(ExpressionStatement node) {
    node.expression.accept(this);
  }

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    // noSuchMethod is mandatory to proxify
    if (node.name.name == 'noSuchMethod') return;

    // it's ok to override to have better documentation
    if (node.documentationComment != null) return;

    inheritedMethod = getInheritedElement(node);
    declaration = node;
    if (inheritedMethod != null && _haveSameDeclaration()) {
      node.body.accept(this);
    }
  }

  @override
  visitParenthesizedExpression(ParenthesizedExpression node) {
    node.unParenthesized.accept(this);
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    node.expression?.accept(this);
  }

  @override
  visitSuperExpression(SuperExpression node) {
    rule.reportLint(declaration.name);
  }

  bool _haveSameDeclaration() {
    if (declaration.element.returnType != inheritedMethod.returnType)
      return false;
    if (declaration.element.parameters.length !=
        inheritedMethod.parameters.length) return false;
    for (var i = 0; i < inheritedMethod.parameters.length; i++) {
      final superParam = inheritedMethod.parameters[i];
      final param = declaration.element.parameters[i];
      if (param.type != superParam.type) return false;
      if (param.name != superParam.name) return false;
      if (param.isCovariant != superParam.isCovariant) return false;
      if (param.parameterKind != superParam.parameterKind) return false;
      if (param.defaultValueCode != superParam.defaultValueCode) return false;
    }
    return true;
  }
}

class _UnnecessaryGetterOverrideVisitor
    extends _AbstractUnnecessaryOverrideVisitor {
  _UnnecessaryGetterOverrideVisitor(LintRule rule) : super(rule);

  @override
  ExecutableElement getInheritedElement(node) =>
      DartTypeUtilities.lookUpInheritedConcreteGetter(node);

  @override
  visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.bestElement == inheritedMethod) {
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
  visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.bestElement == inheritedMethod &&
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
  visitBinaryExpression(BinaryExpression node) {
    final parameters = declaration.parameters.parameters;
    if (node.operator.type == declaration.name.token.type &&
        parameters.length == 1 &&
        parameters.first.identifier.bestElement ==
            DartTypeUtilities
                .getCanonicalElementFromIdentifier(node.rightOperand)) {
      final leftPart = node.leftOperand.unParenthesized;
      if (leftPart is SuperExpression) {
        visitSuperExpression(leftPart);
      }
    }
  }

  @override
  visitPrefixExpression(PrefixExpression node) {
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
  visitAssignmentExpression(AssignmentExpression node) {
    final parameters = declaration.parameters.parameters;
    if (parameters.length == 1 &&
        parameters.first.identifier.bestElement ==
            DartTypeUtilities
                .getCanonicalElementFromIdentifier(node.rightHandSide)) {
      final leftPart = node.leftHandSide.unParenthesized;
      if (leftPart is PropertyAccess) {
        _visitPropertyAccess(leftPart);
      }
    }
  }

  _visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.bestElement == inheritedMethod) {
      node.target?.accept(this);
    }
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;
  _Visitor(this.rule);

  @override
  visitMethodDeclaration(MethodDeclaration node) {
    if (node.isStatic) {
      return;
    }
    if (node.operatorKeyword != null) {
      final visitor = new _UnnecessaryOperatorOverrideVisitor(rule);
      visitor.visitMethodDeclaration(node);
    } else if (node.isGetter) {
      final visitor = new _UnnecessaryGetterOverrideVisitor(rule);
      visitor.visitMethodDeclaration(node);
    } else if (node.isSetter) {
      final visitor = new _UnnecessarySetterOverrideVisitor(rule);
      visitor.visitMethodDeclaration(node);
    } else {
      final visitor = new _UnnecessaryMethodOverrideVisitor(rule);
      visitor.visitMethodDeclaration(node);
    }
  }
}
