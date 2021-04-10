// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class IntroduceLocalCastType extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.INTRODUCE_LOCAL_CAST_TYPE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var isExpression = _getCondition(node);
    if (isExpression is! IsExpression) {
      return;
    }
    var castType = isExpression.type.type;
    var castTypeCode = utils.getNodeText(isExpression.type);
    // prepare environment
    var enclosingStatement = _enclosingStatement(isExpression);
    if (enclosingStatement == null) {
      return;
    }
    // prepare location
    int offset;
    String statementPrefix;
    if (isExpression.notOperator == null) {
      offset = enclosingStatement.block.leftBracket.end;
      statementPrefix = utils.getIndent(1);
    } else {
      offset = enclosingStatement.block.rightBracket.end;
      statementPrefix = '';
    }
    // prepare excluded names
    var excluded = <String>{};
    var scopedNameFinder = ScopedNameFinder(offset);
    isExpression.accept(scopedNameFinder);
    excluded.addAll(scopedNameFinder.locals.keys.toSet());
    // name(s)
    var suggestions =
        getVariableNameSuggestionsForExpression(castType, null, excluded);

    if (suggestions.isNotEmpty) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addInsertion(offset, (builder) {
          builder.write(eol + enclosingStatement.prefix + statementPrefix);
          builder.write(castTypeCode);
          builder.write(' ');
          builder.addSimpleLinkedEdit('NAME', suggestions[0],
              kind: LinkedEditSuggestionKind.VARIABLE,
              suggestions: suggestions);
          builder.write(' = ');
          builder.write(utils.getNodeText(isExpression.expression));
          builder.write(';');
          builder.selectHere();
        });
      });
    }
  }

  _EnclosingStatement? _enclosingStatement(IsExpression condition) {
    var statement = condition.thisOrAncestorOfType<Statement>();
    if (statement is IfStatement) {
      var thenStatement = statement.thenStatement;
      if (thenStatement is Block) {
        return _EnclosingStatement(
          utils.getNodePrefix(statement),
          thenStatement,
        );
      }
    } else if (statement is WhileStatement) {
      var body = statement.body;
      if (body is Block) {
        return _EnclosingStatement(
          utils.getNodePrefix(statement),
          body,
        );
      }
    }
    return null;
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static IntroduceLocalCastType newInstance() => IntroduceLocalCastType();

  static Expression? _getCondition(AstNode node) {
    if (node is IfStatement) {
      return node.condition;
    } else if (node is WhileStatement) {
      return node.condition;
    }

    if (node is Expression) {
      var parent = node.parent;
      if (parent is IfStatement && parent.condition == node) {
        return node;
      } else if (parent is WhileStatement && parent.condition == node) {
        return node;
      }
    }

    return null;
  }
}

class _EnclosingStatement {
  final String prefix;
  final Block block;

  _EnclosingStatement(this.prefix, this.block);
}
