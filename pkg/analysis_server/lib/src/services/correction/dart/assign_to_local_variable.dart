// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/name_suggestion.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';

class AssignToLocalVariable extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.ASSIGN_TO_LOCAL_VARIABLE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // prepare enclosing ExpressionStatement
    ExpressionStatement expressionStatement;
    // ignore: unnecessary_this
    for (var node = this.node; node != null; node = node.parent) {
      if (node is ExpressionStatement) {
        expressionStatement = node;
        break;
      }
      if (node is ArgumentList ||
          node is AssignmentExpression ||
          node is Statement ||
          node is ThrowExpression) {
        return;
      }
    }
    if (expressionStatement == null ||
        _hasPrecedingStatementRecovery(expressionStatement)) {
      return;
    }
    // prepare expression
    var expression = expressionStatement.expression;
    var offset = expression.offset;
    // prepare expression type
    var type = expression.staticType;
    if (type.isVoid) {
      return;
    }
    // prepare excluded names
    var excluded = <String>{};
    var scopedNameFinder = ScopedNameFinder(offset);
    expression.accept(scopedNameFinder);
    excluded.addAll(scopedNameFinder.locals.keys.toSet());
    var suggestions =
        getVariableNameSuggestionsForExpression(type, expression, excluded);

    if (suggestions.isNotEmpty) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addInsertion(offset, (builder) {
          builder.write('var ');
          builder.addSimpleLinkedEdit('NAME', suggestions[0],
              kind: LinkedEditSuggestionKind.VARIABLE,
              suggestions: suggestions);
          builder.write(' = ');
        });
      });
    }
  }

  /// Return an instance of this class. Used as a tear-off in `AssistProcessor`.
  static AssignToLocalVariable newInstance() => AssignToLocalVariable();

  /// Return `true` if the given [statement] resulted from a recovery case that
  /// would make the change create even worse errors than the original code.
  static bool _hasPrecedingStatementRecovery(Statement statement) {
    var parent = statement.parent;
    if (parent is Block) {
      var statements = parent.statements;
      var index = statements.indexOf(statement);
      if (index > 0) {
        var precedingStatement = statements[index - 1];
        if (precedingStatement is ExpressionStatement &&
            precedingStatement.semicolon.isSynthetic) {
          return true;
        } else if (precedingStatement is VariableDeclarationStatement &&
            precedingStatement.semicolon.isSynthetic) {
          return true;
        }
      }
    }
    return false;
  }
}
