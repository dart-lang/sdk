// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertToIfCaseStatement extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.CONVERT_TO_IF_CASE_STATEMENT;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (!libraryElement.featureSet.isEnabled(Feature.patterns)) {
      return;
    }

    final ifStatement = node;
    if (ifStatement is! IfStatement) {
      return;
    }

    final location = ifStatement.locationInBlock;
    if (location == null) {
      return;
    }

    // The statement before `if` declares exactly one variable.
    final previousStatement = location.previous;
    final declaredVariable = previousStatement?.asSingleVariableDeclaration;
    if (declaredVariable == null) {
      return;
    }

    // Check that the declared variable is not used after `if`.
    bool hasReferencesAfterThen() {
      final visitor = _ReferenceVisitor(declaredVariable.element);
      ifStatement.elseStatement?.accept(visitor);
      for (final statement in location.following) {
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
    final isExpression = ifStatement.expression;
    if (isExpression is! IsExpression) {
      return;
    }

    final leftIdentifier = isExpression.expression;
    if (leftIdentifier is! SimpleIdentifier) {
      return;
    }

    final name = declaredVariable.name;
    if (name != leftIdentifier.token.lexeme) {
      return;
    }

    // This check is a bit heavy, so we run it the last.
    if (hasReferencesAfterThen()) {
      return;
    }

    final keyword = declaredVariable.isFinal ? 'final ' : '';
    final typeCode = utils.getNodeText(isExpression.type);
    final patternCode = '$keyword$typeCode $name';

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
    final notEqNull = ifStatement.expression;
    if (notEqNull is! BinaryExpression) {
      return;
    }
    if (notEqNull.operator.type != TokenType.BANG_EQ) {
      return;
    }
    if (notEqNull.rightOperand is! NullLiteral) {
      return;
    }

    final leftIdentifier = notEqNull.leftOperand;
    if (leftIdentifier is! SimpleIdentifier) {
      return;
    }

    final name = declaredVariable.declaration.name.lexeme;
    if (name != leftIdentifier.token.lexeme) {
      return;
    }

    // This check is a bit heavy, so we run it the last.
    if (hasReferencesAfterThen()) {
      return;
    }

    final keyword = declaredVariable.isFinal ? 'final' : 'var';
    final patternCode = '$keyword $name?';

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

      final initializer = declaredVariable.initializer;
      final initializerCode = utils.getNodeText(initializer);

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
    if (node.staticElement == element) {
      hasReference = true;
    }
  }
}

class _StatementInBlock {
  final Block block;
  final int index;

  _StatementInBlock({
    required this.block,
    required this.index,
  });

  Iterable<Statement> get following {
    return statements.skip(index + 1);
  }

  Statement? get previous {
    return index > 0 ? statements[index - 1] : null;
  }

  List<Statement> get statements => block.statements;
}

extension on Statement {
  _DeclaredVariable? get asSingleVariableDeclaration {
    final self = this;
    if (self is! VariableDeclarationStatement) {
      return null;
    }

    final declarations = self.variables.variables;
    final declaration = declarations.singleOrNull;
    if (declaration == null) {
      return null;
    }

    final declaredElement = declaration.declaredElement;
    if (declaredElement is! LocalVariableElement) {
      return null;
    }

    final initializer = declaration.initializer;
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

  _StatementInBlock? get locationInBlock {
    final block = parent;
    if (block is! Block) {
      return null;
    }

    final parentStatements = block.statements;
    return _StatementInBlock(
      block: block,
      index: parentStatements.indexOf(this),
    );
  }
}
