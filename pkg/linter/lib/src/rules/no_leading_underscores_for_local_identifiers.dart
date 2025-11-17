// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';
import '../util/ascii_utils.dart';

const _desc = r'Avoid leading underscores for local identifiers.';

class NoLeadingUnderscoresForLocalIdentifiers extends AnalysisRule {
  NoLeadingUnderscoresForLocalIdentifiers()
    : super(
        name: LintNames.no_leading_underscores_for_local_identifiers,
        description: _desc,
      );

  @override
  DiagnosticCode get diagnosticCode =>
      diag.noLeadingUnderscoresForLocalIdentifiers;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addCatchClause(this, visitor);
    registry.addDeclaredIdentifier(this, visitor);
    registry.addFormalParameterList(this, visitor);
    registry.addForPartsWithDeclarations(this, visitor);
    registry.addFunctionDeclarationStatement(this, visitor);
    registry.addDeclaredVariablePattern(this, visitor);
    registry.addVariableDeclarationStatement(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  void checkIdentifier(Token? id) {
    if (id == null) return;
    if (!id.lexeme.hasLeadingUnderscore) return;
    if (id.lexeme.isJustUnderscores) return;

    rule.reportAtToken(id, arguments: [id.lexeme]);
  }

  @override
  void visitCatchClause(CatchClause node) {
    checkIdentifier(node.exceptionParameter?.name);
    checkIdentifier(node.stackTraceParameter?.name);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    checkIdentifier(node.name);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    if (node.parent.isFieldNameShortcut) return;
    checkIdentifier(node.name);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    if (node.parent case PrimaryConstructorDeclaration primary) {
      if (primary.parent is ExtensionTypeDeclaration) {
        return;
      }
    }

    for (var parameter in node.parameters) {
      if (parameter is DefaultFormalParameter) {
        parameter = parameter.parameter;
      }
      if (parameter is FieldFormalParameter ||
          parameter is SuperFormalParameter) {
        // These are not local identifiers.
        return;
      }
      if (!parameter.isNamed) {
        // Named parameters produce a `private_optional_parameter` diagnostic.
        checkIdentifier(parameter.name);
      }
    }
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    for (var variable in node.variables.variables) {
      checkIdentifier(variable.name);
    }
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    checkIdentifier(node.functionDeclaration.name);
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    for (var variable in node.variables.variables) {
      checkIdentifier(variable.name);
    }
  }
}
