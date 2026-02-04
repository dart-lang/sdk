// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToIfCaseStatement extends ResolvedCorrectionProducer {
  ConvertToIfCaseStatement({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.convertToIfCaseStatement;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (!isEnabled(Feature.patterns)) {
      return;
    }

    var ifStatement = node;
    if (ifStatement is! IfStatement) {
      return;
    }

    var location = ifStatement.statementLocation;
    if (location == null) {
      return;
    }

    // The statement before `if` declares exactly one variable.
    var declaredVariable = location.previous?.asSingleVariableDeclaration;
    if (declaredVariable == null) {
      return;
    }

    // Check that the declared variable is not used after `if`.
    bool hasReferencesAfterThen() {
      var visitor = _ReferenceVisitor(declaredVariable.element);
      ifStatement.elseStatement?.accept(visitor);
      for (var statement in location.following) {
        statement.accept(visitor);
      }
      return visitor.hasReference;
    }

    // if (v is MyType) {}
    await _isType(
      builder: builder,
      declaredVariable: declaredVariable,
      ifStatement: ifStatement,
      hasReferencesAfterThen: hasReferencesAfterThen,
    );

    // if (v != null) {}
    await _notEqNull(
      builder: builder,
      declaredVariable: declaredVariable,
      ifStatement: ifStatement,
      hasReferencesAfterThen: hasReferencesAfterThen,
    );
  }

  Future<void> _isType({
    required ChangeBuilder builder,
    required _DeclaredVariable declaredVariable,
    required IfStatement ifStatement,
    required bool Function() hasReferencesAfterThen,
  }) async {
    var isExpression = ifStatement.expression;
    if (isExpression is! IsExpression) {
      return;
    }

    var leftIdentifier = isExpression.expression;
    if (leftIdentifier is! SimpleIdentifier) {
      return;
    }

    var name = declaredVariable.name;
    if (name != leftIdentifier.token.lexeme) {
      return;
    }

    // This check is a bit heavy, so we run it the last.
    if (hasReferencesAfterThen()) {
      return;
    }

    var keyword = declaredVariable.isFinal ? 'final ' : '';
    var typeCode = utils.getNodeText(isExpression.type);
    var patternCode = '$keyword$typeCode $name';

    await _rewriteIfStatement(
      builder: builder,
      declaredVariable: declaredVariable,
      ifStatement: ifStatement,
      patternCode: patternCode,
    );
  }

  Future<void> _notEqNull({
    required ChangeBuilder builder,
    required _DeclaredVariable declaredVariable,
    required IfStatement ifStatement,
    required bool Function() hasReferencesAfterThen,
  }) async {
    var notEqNull = ifStatement.expression;
    if (notEqNull is! BinaryExpression) {
      return;
    }
    if (notEqNull.operator.type != TokenType.BANG_EQ) {
      return;
    }
    if (notEqNull.rightOperand is! NullLiteral) {
      return;
    }

    var leftIdentifier = notEqNull.leftOperand;
    if (leftIdentifier is! SimpleIdentifier) {
      return;
    }

    var name = declaredVariable.declaration.name.lexeme;
    if (name != leftIdentifier.token.lexeme) {
      return;
    }

    // This check is a bit heavy, so we run it the last.
    if (hasReferencesAfterThen()) {
      return;
    }

    var keyword = declaredVariable.isFinal ? 'final' : 'var';
    var patternCode = '$keyword $name?';

    await _rewriteIfStatement(
      builder: builder,
      declaredVariable: declaredVariable,
      ifStatement: ifStatement,
      patternCode: patternCode,
    );
  }

  Future<void> _rewriteIfStatement({
    required ChangeBuilder builder,
    required _DeclaredVariable declaredVariable,
    required IfStatement ifStatement,
    required String patternCode,
  }) async {
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(
        range.startStart(declaredVariable.statement, ifStatement),
      );

      var initializer = declaredVariable.initializer;
      var initializerCode = utils.getNodeText(initializer);

      builder.addSimpleReplacement(
        range.node(ifStatement.expression),
        '$initializerCode case $patternCode',
      );
    });
  }
}

class _DeclaredVariable {
  final VariableDeclarationStatement statement;
  final VariableDeclaration declaration;
  final LocalVariableElement element;
  final Expression initializer;

  _DeclaredVariable({
    required this.statement,
    required this.declaration,
    required this.element,
    required this.initializer,
  });

  bool get isFinal => element.isFinal;

  String get name => declaration.name.lexeme;
}

class _ReferenceVisitor extends RecursiveAstVisitor<void> {
  final LocalVariableElement element;
  bool hasReference = false;

  _ReferenceVisitor(this.element);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.element == element) {
      hasReference = true;
    }
  }
}

class _StatementLocation {
  final Statement? previous;
  final Iterable<Statement> following;

  _StatementLocation({required this.previous, required this.following});
}

extension on Statement {
  _DeclaredVariable? get asSingleVariableDeclaration {
    var self = this;
    if (self is! VariableDeclarationStatement) {
      return null;
    }

    var declarations = self.variables.variables;
    var declaration = declarations.singleOrNull;
    if (declaration == null) {
      return null;
    }

    var declaredElement = declaration.declaredFragment?.element;
    if (declaredElement is! LocalVariableElement) {
      return null;
    }

    var initializer = declaration.initializer;
    if (initializer == null) {
      return null;
    }

    return _DeclaredVariable(
      statement: self,
      declaration: declaration,
      element: declaredElement,
      initializer: initializer,
    );
  }

  _StatementLocation? get statementLocation {
    switch (parent) {
      case Block(:var statements):
      case SwitchPatternCase(:var statements):
      case SwitchDefault(:var statements):
        var index = statements.indexOf(this);
        return _StatementLocation(
          previous: index > 0 ? statements[index - 1] : null,
          following: statements.skip(index + 1),
        );
      default:
        return null;
    }
  }
}
