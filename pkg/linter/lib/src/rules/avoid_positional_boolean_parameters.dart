// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';
import '../extensions.dart';

const _desc = r'Avoid positional boolean parameters.';

class AvoidPositionalBooleanParameters extends LintRule {
  AvoidPositionalBooleanParameters()
      : super(
          name: LintNames.avoid_positional_boolean_parameters,
          description: _desc,
        );

  @override
  LintCode get lintCode => LinterLintCode.avoid_positional_boolean_parameters;

  @override
  void registerNodeProcessors(
      NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this, context);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addGenericFunctionType(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final LintRule rule;
  final LinterContext context;

  _Visitor(this.rule, this.context);

  void checkParams(List<FormalParameter>? parameters) {
    var parameterToLint = parameters?.firstWhereOrNull(_isBoolean);
    if (parameterToLint != null) {
      rule.reportLint(parameterToLint);
    }
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // Don't lint augmentations.
    if (node.isAugmentation) return;

    var declaredElement = node.declaredFragment?.element;
    if (declaredElement != null && !declaredElement.isPrivate) {
      checkParams(node.parameters.parameters);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Don't lint augmentations.
    if (node.isAugmentation) return;

    var element = node.declaredFragment?.element;
    if (element != null && !element.isPrivate) {
      checkParams(node.functionExpression.parameters?.parameters);
    }
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    checkParams(node.parameters.parameters);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Don't lint augmentations.
    if (node.isAugmentation) return;

    var declaredElement = node.declaredFragment?.element;
    if (declaredElement != null &&
        !node.isSetter &&
        !declaredElement.isPrivate &&
        !node.isOperator &&
        !node.hasInheritedMethod &&
        !_isOverridingMember(declaredElement)) {
      checkParams(node.parameters?.parameters);
    }
  }

  bool _isOverridingMember(Element2 member) {
    var classElement = member.thisOrAncestorOfType2<ClassElement2>();
    if (classElement == null) return false;

    var name = member.name3;
    if (name == null) return false;

    var libraryUri = classElement.library2.uri;
    return context.inheritanceManager
            .getInherited3(classElement.thisType, Name(libraryUri, name)) !=
        null;
  }

  static bool _isBoolean(FormalParameter node) {
    var type = node.declaredFragment?.element.type;
    return !node.isNamed && type is InterfaceType && type.isDartCoreBool;
  }
}
