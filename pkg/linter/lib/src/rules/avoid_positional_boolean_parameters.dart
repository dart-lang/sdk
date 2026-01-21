// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:collection/collection.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';

const _desc = r'Avoid positional boolean parameters.';

class AvoidPositionalBooleanParameters extends AnalysisRule {
  AvoidPositionalBooleanParameters()
    : super(
        name: LintNames.avoid_positional_boolean_parameters,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode => diag.avoidPositionalBooleanParameters;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addGenericFunctionType(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addPrimaryConstructorDeclaration(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  void checkParams(List<FormalParameter>? parameters) {
    var parameterToLint = parameters?.firstWhereOrNull(_isBoolean);
    if (parameterToLint != null) {
      rule.reportAtNode(parameterToLint);
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

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    // Don't lint augmentations.
    if (node.isAugmentation) return;

    var declaredElement = node.declaredFragment?.element;
    if (declaredElement != null && !declaredElement.isPrivate) {
      checkParams(node.formalParameters.parameters);
    }
  }

  bool _isOverridingMember(Element member) {
    var classElement = member.thisOrAncestorOfType<ClassElement>();
    if (classElement == null) return false;

    var name = member.name;
    if (name == null) return false;

    var libraryUri = classElement.library.uri;
    return classElement.getInheritedMember(Name(libraryUri, name)) != null;
  }

  static bool _isBoolean(FormalParameter node) {
    var type = node.declaredFragment?.element.type;
    return !node.isNamed && type is InterfaceType && type.isDartCoreBool;
  }
}
