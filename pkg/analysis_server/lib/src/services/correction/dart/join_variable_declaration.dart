// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class JoinVariableDeclaration extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.JOIN_VARIABLE_DECLARATION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is AssignmentExpression &&
          parent.leftHandSide == node &&
          parent.parent is ExpressionStatement) {
        await _joinOnAssignment(builder, node, parent);
        return;
      }
    }
    var declList = node.thisOrAncestorOfType<VariableDeclarationList>();
    if (declList != null && declList.variables.length == 1) {
      await _joinOnDeclaration(builder, declList);
    }
  }

  /// Join the declaration when the variable is on the left-hand side of an
  /// assignment.
  Future<void> _joinOnAssignment(ChangeBuilder builder, SimpleIdentifier left,
      AssignmentExpression assignment) async {
    // Check that assignment is not a compound assignment.
    if (assignment.operator.type != TokenType.EQ) {
      return;
    }

    // The assignment must be a separate statement.
    var assignmentStatement = assignment.parent;
    if (assignmentStatement is! ExpressionStatement) {
      return;
    }

    // ...in a Block.
    var block = assignmentStatement.parent;
    if (block is! Block) {
      return;
    }

    // Prepare the index in the enclosing Block.
    var statements = block.statements;
    var assignmentStatementIndex = statements.indexOf(assignmentStatement);
    if (assignmentStatementIndex < 1) {
      return;
    }

    // The immediately previous statement must be a declaration.
    var declarationStatement = statements[assignmentStatementIndex - 1];
    if (declarationStatement is! VariableDeclarationStatement) {
      return;
    }

    // Only one variable must be declared.
    var declaredVariables = declarationStatement.variables.variables;
    if (declaredVariables.length != 1) {
      return;
    }

    // The declared variable must be the one that is assigned.
    // There must be no initializer.
    var declaredVariable = declaredVariables.single;
    if (declaredVariable.declaredElement != left.staticElement ||
        declaredVariable.initializer != null) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.endStart(declaredVariable, assignment.operator),
        ' ',
      );
    });
  }

  /// Join the declaration when the variable is on the left-hand side of an
  /// assignment.
  Future<void> _joinOnDeclaration(
      ChangeBuilder builder, VariableDeclarationList declList) async {
    // Only one variable must be declared.
    var declaredVariables = declList.variables;
    if (declaredVariables.length != 1) {
      return;
    }

    // The declared variable must not be initialized.
    var declaredVariable = declaredVariables.single;
    if (declaredVariable.initializer != null) {
      return;
    }

    // The declaration must be a separate statement.
    var declarationStatement = declList.parent;
    if (declarationStatement is! VariableDeclarationStatement) {
      return;
    }

    // ...in a Block.
    var block = declarationStatement.parent;
    if (block is! Block) {
      return;
    }

    // The declaration statement must not be the last in the block.
    var statements = block.statements;
    var declarationStatementIndex = statements.indexOf(declarationStatement);
    if (declarationStatementIndex < 0 ||
        declarationStatementIndex >= statements.length - 1) {
      return;
    }

    // The immediately following statement must be an assignment statement.
    var assignmentStatement = statements[declarationStatementIndex + 1];
    if (assignmentStatement is! ExpressionStatement) {
      return;
    }

    // Really an assignment.
    var assignment = assignmentStatement.expression;
    if (assignment is! AssignmentExpression) {
      return;
    }

    // The assignment should write into the declared variable.
    if (assignment.writeElement != declaredVariable.declaredElement) {
      return;
    }

    // The assignment must be pure.
    if (assignment.operator.type != TokenType.EQ) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.endStart(declaredVariable.name, assignment.operator),
        ' ',
      );
    });
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static JoinVariableDeclaration newInstance() => JoinVariableDeclaration();
}
