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
    // may be on Statement with Conditional
    var statement = node.thisOrAncestorOfType<Statement>();
    if (statement == null) {
      return;
    }

    // Type v = conditional;
    if (statement is VariableDeclarationStatement) {
      return _variableDeclarationStatement(builder, statement);
    }

    // v = conditional;
    if (statement is ExpressionStatement) {
      var expression = statement.expression;
      if (expression is AssignmentExpression) {
        return _assignmentExpression(builder, statement, expression);
      }
    }

    // return conditional;
    if (statement is ReturnStatement) {
      return _returnStatement(builder, statement);
    }
  }

  Future<void> _assignmentExpression(
    ChangeBuilder builder,
    ExpressionStatement statement,
    AssignmentExpression assignment,
  ) async {
    var conditional = assignment.rightHandSide;
    if (assignment.operator.type == TokenType.EQ &&
        conditional is ConditionalExpression) {
      var indent = utils.getIndent(1);
      var prefix = utils.getNodePrefix(statement);

      await builder.addDartFileEdit(file, (builder) {
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
      });
    }
  }

  Future<void> _returnStatement(
    ChangeBuilder builder,
    ReturnStatement statement,
  ) async {
    var conditional = statement.expression;
    if (conditional is ConditionalExpression) {
      var indent = utils.getIndent(1);
      var prefix = utils.getNodePrefix(statement);

      await builder.addDartFileEdit(file, (builder) {
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
      });
    }
  }

  Future<void> _variableDeclarationStatement(
    ChangeBuilder builder,
    VariableDeclarationStatement statement,
  ) async {
    for (var variable in statement.variables.variables) {
      var conditional = variable.initializer;
      if (conditional is ConditionalExpression) {
        var indent = utils.getIndent(1);
        var prefix = utils.getNodePrefix(statement);

        await builder.addDartFileEdit(file, (builder) {
          var variable = conditional.parent as VariableDeclaration;
          var variableList = variable.parent as VariableDeclarationList;
          if (variableList.type == null) {
            var type = variable.declaredElement!.type;
            var keyword = variableList.keyword;
            if (keyword != null && keyword.keyword == Keyword.VAR) {
              builder.addReplacement(range.token(keyword), (builder) {
                builder.writeType(type);
              });
            } else {
              builder.addInsertion(variable.name.offset, (builder) {
                builder.writeType(type);
                builder.write(' ');
              });
            }
          }
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
        });
      }
    }
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static ReplaceConditionalWithIfElse newInstance() =>
      ReplaceConditionalWithIfElse();
}
