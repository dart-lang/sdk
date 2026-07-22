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

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';

const _desc = r'Avoid positional boolean parameters.';

class AvoidPositionalBooleanParameters extends AnalysisRule {
  new()
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
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addGenericFunctionType(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addPrimaryConstructorDeclaration(this, visitor);
  }
}

class _Visitor(final AnalysisRule _rule) extends SimpleAstVisitor<void> {
  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    // Don't lint augmentations.
    if (node.isAugmentation) return;

    var declaredElement = node.declaredFragment?.element;
    if (declaredElement != null && !declaredElement.isPrivate) {
      _checkParams(node.parameters.parameters);
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Don't lint augmentations.
    if (node.isAugmentation) return;

    var element = node.declaredFragment?.element;
    if (element != null && !element.isPrivate) {
      _checkParams(node.functionExpression.parameters?.parameters);
    }
  }

  @override
  void visitGenericFunctionType(GenericFunctionType node) {
    _checkParams(node.parameters.parameters);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    // Don't lint augmentations.
    if (node.isAugmentation) return;
    if (node.isGetter) return;
    if (node.isSetter) return;
    if (node.isOperator) return;
    if (node.hasInheritedMethod) return;

    var declaredElement = node.declaredFragment?.element;
    if (declaredElement != null &&
        !declaredElement.isPrivate &&
        !declaredElement.isOverridingMember) {
      _checkParams(node.parameters?.parameters);
    }
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    // Don't lint augmentations.
    if (node.isAugmentation) return;

    var declaredElement = node.declaredFragment?.element;
    if (declaredElement != null && !declaredElement.isPrivate) {
      _checkParams(node.formalParameters.parameters);
    }
  }

  void _checkParams(List<FormalParameter>? parameters) {
    if (parameters == null) return;
    var positionalBooleanParameters = parameters.where((p) {
      var type = p.declaredFragment?.element.type;
      return p.isPositional && type is InterfaceType && type.isDartCoreBool;
    }).toList();

    // Only report if there are at least two positional bool parameters.
    if (positionalBooleanParameters case [_, var second, ...]) {
      _rule.reportAtNode(second);
    }
  }
}

extension on Element {
  bool get isOverridingMember {
    if (name case var name?) {
      var classElement = thisOrAncestorOfType<ClassElement>();
      if (classElement == null) return false;

      var libraryUri = classElement.library.uri;
      return classElement.getInheritedMember(Name(libraryUri, name)) != null;
    }
    return false;
  }
}
