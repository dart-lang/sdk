// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../extensions.dart';
import '../util/dart_type_utilities.dart';

const _desc =
    r"Don't override a method to do a super method invocation with the same"
    r' parameters.';

class UnnecessaryOverrides extends LintRule {
  UnnecessaryOverrides()
    : super(name: LintNames.unnecessary_overrides, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => LinterLintCode.unnecessary_overrides;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addMethodDeclaration(this, visitor);
  }
}

abstract class _AbstractUnnecessaryOverrideVisitor
    extends SimpleAstVisitor<void> {
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
    rule.reportAtToken(declaration.name);
  }

  /// Returns whether [declaration] is annotated with any metadata (other than
  /// `@override` or `@Override`).
  bool _addsMetadata() {
    var metadata = declaration.declaredFragment?.element.metadata;
    if (metadata != null) {
      for (var annotation in metadata.annotations) {
        if (annotation.isOverride) continue;
        if (annotation.isProtected && _inheritedMethod.metadata.hasProtected) {
          continue;
        }

        // Any other annotation implies a meaningful override.
        return true;
      }
    }
    return false;
  }

  bool _haveSameDeclaration() {
    var declaredElement = declaration.declaredFragment?.element;
    if (declaredElement == null) {
      return false;
    }
    if (declaredElement.returnType != _inheritedMethod.returnType) {
      return false;
    }
    if (declaredElement.formalParameters.length !=
        _inheritedMethod.formalParameters.length) {
      return false;
    }
    for (var i = 0; i < _inheritedMethod.formalParameters.length; i++) {
      var superParam = _inheritedMethod.formalParameters[i];
      var param = declaredElement.formalParameters[i];
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
    var declaredElement = declaration.declaredFragment?.element;
    if (declaredElement == null) return false;
    if (declaredElement.metadata.hasProtected) {
      return false;
    }
    return _inheritedMethod.metadata.hasProtected;
  }

  bool _sameKind(FormalParameterElement first, FormalParameterElement second) {
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
    var element = node.declaredFragment?.element;
    if (element == null) return null;
    var enclosingElement = element.enclosingElement;
    if (enclosingElement is! InterfaceElement) return null;
    var getterName = element.name;
    if (getterName == null) return null;
    return enclosingElement.thisType.lookUpGetter(
      getterName,
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
    var element = node.declaredFragment?.element;
    if (element == null) return null;

    var enclosingElement = element.enclosingElement;
    if (enclosingElement is! InterfaceElement) return null;

    return enclosingElement.firstFragment.element.thisType.lookUpMethod(
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
          node.argumentList.arguments,
          declarationParameters.parameters,
        )) {
      node.target?.accept(this);
    }
  }
}

class _UnnecessaryOperatorOverrideVisitor
    extends _AbstractUnnecessaryOverrideVisitor {
  _UnnecessaryOperatorOverrideVisitor(super.rule);

  @override
  ExecutableElement? getInheritedElement(node) {
    var element = node.declaredFragment?.element;
    if (element == null) return null;
    var enclosingElement = element.enclosingElement;
    if (enclosingElement is! InterfaceElement) return null;
    var methodName = element.name;
    if (methodName == null) return null;
    return enclosingElement.thisType.lookUpMethod(
      methodName,
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
        parameters.first.declaredFragment?.element ==
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
    var element = node.declaredFragment?.element;
    if (element == null) return null;
    var enclosingElement = element.enclosingElement;
    if (enclosingElement is! InterfaceElement) return null;
    return enclosingElement.thisType.lookUpSetter(
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
        parameters.first.declaredFragment?.element ==
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
