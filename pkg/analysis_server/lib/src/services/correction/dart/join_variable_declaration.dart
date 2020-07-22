// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class JoinVariableDeclaration extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.JOIN_VARIABLE_DECLARATION;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is AssignmentExpression &&
          parent.leftHandSide == node &&
          parent.parent is ExpressionStatement) {
        await _joinOnAssignment(builder, parent);
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
  Future<void> _joinOnAssignment(
      ChangeBuilder builder, AssignmentExpression assignExpression) async {
    // Check that assignment is not a compound assignment.
    if (assignExpression.operator.type != TokenType.EQ) {
      return;
    }
    // prepare "declaration" statement
    var element = (node as SimpleIdentifier).staticElement;
    if (element == null) {
      return;
    }
    var declOffset = element.nameOffset;
    var unit = resolvedResult.unit;
    var declNode = NodeLocator(declOffset).searchWithin(unit);
    if (declNode != null &&
        declNode.parent is VariableDeclaration &&
        (declNode.parent as VariableDeclaration).name == declNode &&
        declNode.parent.parent is VariableDeclarationList &&
        declNode.parent.parent.parent is VariableDeclarationStatement) {
    } else {
      return;
    }
    var decl = declNode.parent as VariableDeclaration;
    var declStatement = decl.parent.parent as VariableDeclarationStatement;
    // may be has initializer
    if (decl.initializer != null) {
      return;
    }
    // check that "declaration" statement declared only one variable
    if (declStatement.variables.variables.length != 1) {
      return;
    }
    // check that the "declaration" and "assignment" statements are
    // parts of the same Block
    var assignStatement = node.parent.parent as ExpressionStatement;
    if (assignStatement.parent is Block &&
        assignStatement.parent == declStatement.parent) {
    } else {
      return;
    }
    var block = assignStatement.parent as Block;
    // check that "declaration" and "assignment" statements are adjacent
    List<Statement> statements = block.statements;
    if (statements.indexOf(assignStatement) ==
        statements.indexOf(declStatement) + 1) {
    } else {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
          range.endStart(declNode, assignExpression.operator), ' ');
    });
  }

  /// Join the declaration when the variable is on the left-hand side of an
  /// assignment.
  Future<void> _joinOnDeclaration(
      ChangeBuilder builder, VariableDeclarationList declList) async {
    // prepare enclosing VariableDeclarationList
    var decl = declList.variables[0];
    // already initialized
    if (decl.initializer != null) {
      return;
    }
    // prepare VariableDeclarationStatement in Block
    if (declList.parent is VariableDeclarationStatement &&
        declList.parent.parent is Block) {
    } else {
      return;
    }
    var declStatement = declList.parent as VariableDeclarationStatement;
    var block = declStatement.parent as Block;
    List<Statement> statements = block.statements;
    // prepare assignment
    // declaration should not be last Statement
    var declIndex = statements.indexOf(declStatement);
    if (declIndex < statements.length - 1) {
    } else {
      return;
    }
    // next Statement should be assignment
    var assignStatement = statements[declIndex + 1];
    if (assignStatement is ExpressionStatement) {
    } else {
      return;
    }
    var expressionStatement = assignStatement as ExpressionStatement;
    // expression should be assignment
    if (expressionStatement.expression is AssignmentExpression) {
    } else {
      return;
    }
    var assignExpression =
        expressionStatement.expression as AssignmentExpression;
    // check that pure assignment
    if (assignExpression.operator.type != TokenType.EQ) {
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
          range.endStart(decl.name, assignExpression.operator), ' ');
    });
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static JoinVariableDeclaration newInstance() => JoinVariableDeclaration();
}
