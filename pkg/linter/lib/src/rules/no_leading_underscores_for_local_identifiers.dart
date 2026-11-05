// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/ast.dart'; // ignore: implementation_imports

import '../analyzer.dart';
import '../diagnostic.dart' as diag;
import '../extensions.dart';
import '../util/ascii_utils.dart';

const _desc = r'Avoid leading underscores for local identifiers.';

class NoLeadingUnderscoresForLocalIdentifiers extends MultiAnalysisRule {
  new()
    : super(
        name: LintNames.no_leading_underscores_for_local_identifiers,
        description: _desc,
      );

  @override
  List<DiagnosticCode> get diagnosticCodes => const [
    diag.noLeadingUnderscoresForLocalIdentifiers,
    diag.noLeadingUnderscoresForLocalIdentifiersShadowed,
  ];

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

class _Visitor(final MultiAnalysisRule rule) extends SimpleAstVisitor<void> {
  void checkIdentifier(Token? id, AstNode? node, Element? element) {
    if (id == null || node == null) return;
    if (!id.lexeme.hasLeadingUnderscore) return;
    if (id.lexeme.isJustUnderscores) return;

    rule.reportAtToken(
      id,
      arguments: [id.lexeme],
      diagnosticCode: _isShadowing(id.lexeme, node, element)
          ? diag.noLeadingUnderscoresForLocalIdentifiersShadowed
          : diag.noLeadingUnderscoresForLocalIdentifiers,
    );
  }

  @override
  void visitCatchClause(CatchClause node) {
    checkIdentifier(
      node.exceptionParameter?.name,
      node.exceptionParameter,
      node.exceptionParameter?.declaredFragment?.element,
    );
    checkIdentifier(
      node.stackTraceParameter?.name,
      node.stackTraceParameter,
      node.stackTraceParameter?.declaredFragment?.element,
    );
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    checkIdentifier(node.name, node, node.declaredFragment?.element);
  }

  @override
  void visitDeclaredVariablePattern(DeclaredVariablePattern node) {
    if (node.parent.isFieldNameShortcut) return;
    checkIdentifier(node.name, node, node.declaredFragment?.element);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    if (node.parent case PrimaryConstructorDeclaration primary) {
      if (primary.parent is ExtensionTypeDeclaration) {
        return;
      }
    }

    for (var parameter in node.parameters) {
      if (parameter is FieldFormalParameter ||
          parameter is SuperFormalParameter) {
        // These are not local identifiers.
        return;
      }
      if (parameter.declaredFragment?.element is FieldFormalParameterElement) {
        // Declaring parameters must have an underscore if the declared field is
        // intended to be private.
        return;
      }
      if (!parameter.isNamed) {
        // Named parameters produce a `private_optional_parameter` diagnostic.
        checkIdentifier(
          parameter.name,
          parameter,
          parameter.declaredFragment?.element,
        );
      }
    }
  }

  @override
  void visitForPartsWithDeclarations(ForPartsWithDeclarations node) {
    for (var variable in node.variables.variables) {
      checkIdentifier(
        variable.name,
        variable,
        variable.declaredFragment?.element,
      );
    }
  }

  @override
  void visitFunctionDeclarationStatement(FunctionDeclarationStatement node) {
    checkIdentifier(
      node.functionDeclaration.name,
      node.functionDeclaration,
      node.functionDeclaration.declaredFragment?.element,
    );
  }

  @override
  void visitVariableDeclarationStatement(VariableDeclarationStatement node) {
    for (var variable in node.variables.variables) {
      checkIdentifier(
        variable.name,
        variable,
        variable.declaredFragment?.element,
      );
    }
  }

  /// Whether removing the leading underscore from [lexeme] would, at some
  /// reference to the element declared by [node], make that reference
  /// resolve to a different element, or would already name an accessible
  /// member of an enclosing class, mixin, enum, or extension type.
  bool _isShadowing(String lexeme, AstNode node, Element? element) {
    var newName = lexeme.substring(1);
    if (newName.isEmpty) return false;

    return element != null &&
        node.enclosingBody.isShadowedAtSomeReference(newName, element);
  }
}
