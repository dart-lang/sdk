// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;

const _desc =
    r"Don't reassign references to parameters of functions or methods.";

bool _isFormalParameterReassigned(
  FormalParameter parameter,
  AssignmentExpression assignment,
) {
  var leftHandSide = assignment.leftHandSide;
  return leftHandSide is SimpleIdentifier &&
      leftHandSide.element == parameter.declaredFragment?.element;
}

class ParameterAssignments extends AnalysisRule {
  ParameterAssignments()
    : super(name: LintNames.parameter_assignments, description: _desc);

  @override
  DiagnosticCode get diagnosticCode => diag.parameterAssignments;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addConstructorDeclaration(this, visitor);
    registry.addFunctionDeclaration(this, visitor);
    registry.addFunctionExpression(this, visitor);
    registry.addMethodDeclaration(this, visitor);
    registry.addPrimaryConstructorDeclaration(this, visitor);
  }
}

class _DeclarationVisitor extends RecursiveAstVisitor<void> {
  final FormalParameter _parameter;
  final AnalysisRule rule;

  bool hasBeenAssigned = false;

  _DeclarationVisitor(this._parameter, this.rule);

  Element? get parameterElement => _parameter.declaredFragment?.element;

  /// Whether the default value of [_parameter] is `null`.
  bool get _defaultValueIsNull =>
      _parameter.isOptional && _parameter.defaultClause == null;

  void checkPatternElements(DartPattern node) {
    NodeList<PatternField>? fields;
    if (node is RecordPattern) fields = node.fields;
    if (node is ObjectPattern) fields = node.fields;
    if (fields != null) {
      for (var field in fields) {
        if (field.pattern.element == parameterElement) {
          reportLint(node);
        }
      }
    } else {
      List<AstNode>? elements;
      if (node is ListPattern) elements = node.elements;
      if (node is MapPattern) elements = node.elements;
      if (elements == null) return;
      for (var element in elements) {
        if (element is MapPatternEntry) {
          element = element.value;
        }
        if (element.element == parameterElement) {
          reportLint(node);
        }
      }
    }
  }

  void reportLint(AstNode node) {
    rule.reportAtNode(node, arguments: [_parameter.name!.lexeme]);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    if (!_isFormalParameterReassigned(_parameter, node)) return;

    if (!_defaultValueIsNull) {
      reportLint(node);
      return;
    }

    if (node.operator.type == TokenType.QUESTION_QUESTION_EQ) {
      if (hasBeenAssigned) {
        reportLint(node);
      }
      hasBeenAssigned = true;
    } else {
      reportLint(node);
    }

    super.visitAssignmentExpression(node);
  }

  @override
  visitPatternAssignment(PatternAssignment node) {
    checkPatternElements(node.pattern);

    super.visitPatternAssignment(node);
  }

  @override
  visitPostfixExpression(PostfixExpression node) {
    if (!_defaultValueIsNull) {
      if (node.operator.type == TokenType.PLUS_PLUS ||
          node.operator.type == TokenType.MINUS_MINUS) {
        var operand = node.operand;
        if (operand is SimpleIdentifier &&
            operand.element == parameterElement) {
          reportLint(node);
        }
      }
    }

    super.visitPostfixExpression(node);
  }

  @override
  visitPrefixExpression(PrefixExpression node) {
    if (!_defaultValueIsNull) {
      if (node.operator.type == TokenType.PLUS_PLUS ||
          node.operator.type == TokenType.MINUS_MINUS) {
        var operand = node.operand;
        if (operand is SimpleIdentifier &&
            operand.element == parameterElement) {
          reportLint(node);
        }
      }
    }

    super.visitPrefixExpression(node);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _checkParameters(node.parameters, node.body);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _checkParameters(
      node.functionExpression.parameters,
      node.functionExpression.body,
    );
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration) {
      _checkParameters(node.parameters, node.body);
    }
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _checkParameters(node.parameters, node.body);
  }

  @override
  void visitPrimaryConstructorDeclaration(PrimaryConstructorDeclaration node) {
    var body = node.body;
    if (body != null) {
      _checkParameters(node.formalParameters, body.body);
    }
  }

  void _checkParameters(FormalParameterList? parameterList, FunctionBody body) {
    if (parameterList == null) return;

    for (var parameter in parameterList.parameters) {
      var declaredElement = parameter.declaredFragment?.element;
      if (declaredElement != null &&
          body.isPotentiallyMutatedInScope(declaredElement)) {
        body.accept(_DeclarationVisitor(parameter, rule));
      }
    }
  }
}

extension on AstNode {
  Element? get element => switch (this) {
    AssignedVariablePattern(:var element) => element,
    _ => null,
  };
}
