// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
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
import 'package:analyzer/src/dart/element/extensions.dart' // ignore: implementation_imports
    show Element2Extension;

import '../analyzer.dart';
import '../util/scope.dart';

const _desc = r'Avoid types as parameter names.';

class AvoidTypesAsParameterNames extends MultiAnalysisRule {
  AvoidTypesAsParameterNames()
    : super(name: LintNames.avoid_types_as_parameter_names, description: _desc);

  @override
  List<DiagnosticCode> get diagnosticCodes => [
    LinterLintCode.avoid_types_as_parameter_names_type_parameter,
    LinterLintCode.avoid_types_as_parameter_names_formal_parameter,
  ];

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this, context);
    registry.addFormalParameterList(this, visitor);
    registry.addCatchClause(this, visitor);
    registry.addTypeParameterList(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final MultiAnalysisRule rule;
  final RuleContext context;

  _Visitor(this.rule, this.context);

  @override
  void visitCatchClause(CatchClause node) {
    var parameter = node.exceptionParameter;
    if (parameter != null && _isTypeName(node, parameter.name)) {
      rule.reportAtNode(
        parameter,
        arguments: [parameter.name.lexeme],
        diagnosticCode:
            LinterLintCode.avoid_types_as_parameter_names_formal_parameter,
      );
    }
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    for (var parameter in node.parameters) {
      var declaredElement = parameter.declaredFragment?.element;
      var name = parameter.name;
      if (declaredElement != null &&
          declaredElement is! FieldFormalParameterElement &&
          declaredElement.hasImplicitType &&
          name != null &&
          _isTypeName(node, name)) {
        rule.reportAtToken(
          name,
          arguments: [name.lexeme],
          diagnosticCode:
              LinterLintCode.avoid_types_as_parameter_names_formal_parameter,
        );
      }
    }
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    for (var typeParameter in node.typeParameters) {
      var declaredElement = typeParameter.declaredFragment?.element;
      var name = typeParameter.name;
      var scope = node.parent;
      var isShadowedByTypeParameter = false;
      // Step out into enclosing scope where this type parameter isn't
      // itself in scope (the type parameter doesn't shadow itself).
      while (scope != null) {
        if (scope is ClassDeclaration ||
            scope is FunctionDeclaration ||
            (scope is FunctionExpression &&
                scope.parent is! FunctionDeclaration) ||
            scope is GenericFunctionType ||
            scope is MethodDeclaration) {
          if (scope is MethodDeclaration) {
            isShadowedByTypeParameter = true;
          }
          scope = scope.parent;
          break;
        }
        scope = scope.parent;
      }
      if (declaredElement != null &&
          scope != null &&
          _isTypeName(
            scope,
            name,
            isShadowedByMethodTypeParameter: isShadowedByTypeParameter,
          )) {
        rule.reportAtToken(
          name,
          arguments: [name.lexeme],
          diagnosticCode:
              LinterLintCode.avoid_types_as_parameter_names_type_parameter,
        );
      }
    }
  }

  bool _isTypeName(
    AstNode scope,
    Token name, {
    bool isShadowedByMethodTypeParameter = false,
  }) {
    var result = resolveNameInScope(
      name.lexeme,
      scope,
      shouldResolveSetter: false,
    );
    if (result.isRequestedName) {
      var element = result.element;
      if (isShadowedByMethodTypeParameter && element is TypeParameterElement) {
        // A type parameter of a static method can only shadow another type
        // parameter when the latter is a type parameter of the enclosing
        // declaration (class, mixin, mixin class, enum, extension, or
        // extension type). We do not lint this case.
        return false;
      }
      return element is ClassElement ||
          element is ExtensionTypeElement ||
          element is TypeAliasElement ||
          (element is TypeParameterElement && !element.isWildcardVariable);
    }
    return false;
  }
}
