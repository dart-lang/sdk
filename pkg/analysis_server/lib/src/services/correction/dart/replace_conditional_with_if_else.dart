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

class ReplaceConditionalWithIfElse extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.REPLACE_CONDITIONAL_WITH_IF_ELSE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    ConditionalExpression conditional;
    // may be on Statement with Conditional
    var statement = node.thisOrAncestorOfType<Statement>();
    if (statement == null) {
      return;
    }
    // variable declaration
    var inVariable = false;
    if (statement is VariableDeclarationStatement) {
      var variableStatement = statement;
      for (var variable in variableStatement.variables.variables) {
        if (variable.initializer is ConditionalExpression) {
          conditional = variable.initializer as ConditionalExpression;
          inVariable = true;
          break;
        }
      }
    }
    // assignment
    var inAssignment = false;
    if (statement is ExpressionStatement) {
      var exprStmt = statement;
      if (exprStmt.expression is AssignmentExpression) {
        var assignment = exprStmt.expression as AssignmentExpression;
        if (assignment.operator.type == TokenType.EQ &&
            assignment.rightHandSide is ConditionalExpression) {
          conditional = assignment.rightHandSide as ConditionalExpression;
          inAssignment = true;
        }
      }
    }
    // return
    var inReturn = false;
    if (statement is ReturnStatement) {
      var returnStatement = statement;
      if (returnStatement.expression is ConditionalExpression) {
        conditional = returnStatement.expression as ConditionalExpression;
        inReturn = true;
      }
    }
    // prepare environment
    var indent = utils.getIndent(1);
    var prefix = utils.getNodePrefix(statement);

    if (inVariable || inAssignment || inReturn) {
      await builder.addDartFileEdit(file, (builder) {
        // Type v = Conditional;
        if (inVariable) {
          var variable = conditional.parent as VariableDeclaration;
          builder.addDeletion(range.endEnd(variable.name, conditional));
          var conditionSrc = utils.getNodeText(conditional.condition);
          var thenSrc = utils.getNodeText(conditional.thenExpression);
          var elseSrc = utils.getNodeText(conditional.elseExpression);
          var name = variable.name.name;
          var src = eol;
          src += prefix + 'if ($conditionSrc) {' + eol;
          src += prefix + indent + '$name = $thenSrc;' + eol;
          src += prefix + '} else {' + eol;
          src += prefix + indent + '$name = $elseSrc;' + eol;
          src += prefix + '}';
          builder.addSimpleReplacement(range.endLength(statement, 0), src);
        }
        // v = Conditional;
        if (inAssignment) {
          var assignment = conditional.parent as AssignmentExpression;
          var leftSide = assignment.leftHandSide;
          var conditionSrc = utils.getNodeText(conditional.condition);
          var thenSrc = utils.getNodeText(conditional.thenExpression);
          var elseSrc = utils.getNodeText(conditional.elseExpression);
          var name = utils.getNodeText(leftSide);
          var src = '';
          src += 'if ($conditionSrc) {' + eol;
          src += prefix + indent + '$name = $thenSrc;' + eol;
          src += prefix + '} else {' + eol;
          src += prefix + indent + '$name = $elseSrc;' + eol;
          src += prefix + '}';
          builder.addSimpleReplacement(range.node(statement), src);
        }
        // return Conditional;
        if (inReturn) {
          var conditionSrc = utils.getNodeText(conditional.condition);
          var thenSrc = utils.getNodeText(conditional.thenExpression);
          var elseSrc = utils.getNodeText(conditional.elseExpression);
          var src = '';
          src += 'if ($conditionSrc) {' + eol;
          src += prefix + indent + 'return $thenSrc;' + eol;
          src += prefix + '} else {' + eol;
          src += prefix + indent + 'return $elseSrc;' + eol;
          src += prefix + '}';
          builder.addSimpleReplacement(range.node(statement), src);
        }
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static ReplaceConditionalWithIfElse newInstance() =>
      ReplaceConditionalWithIfElse();
}
