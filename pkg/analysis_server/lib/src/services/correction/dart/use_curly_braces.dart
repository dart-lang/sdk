// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class UseCurlyBraces extends CorrectionProducer {
  @override
  AssistKind get assistKind => DartAssistKind.USE_CURLY_BRACES;

  @override
  FixKind get fixKind => DartFixKind.ADD_CURLY_BRACES;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var statement = node.thisOrAncestorOfType<Statement>();
    var parent = statement?.parent;

    if (statement is DoStatement) {
      return _doStatement(builder, statement);
    } else if (parent is DoStatement) {
      return _doStatement(builder, parent);
    } else if (statement is ForStatement) {
      return _forStatement(builder, statement);
    } else if (parent is ForStatement) {
      return _forStatement(builder, parent);
    } else if (statement is IfStatement) {
      if (statement.elseKeyword != null &&
          range.token(statement.elseKeyword).contains(selectionOffset)) {
        return _ifStatement(builder, statement, statement.elseStatement);
      } else {
        return _ifStatement(builder, statement, null);
      }
    } else if (parent is IfStatement) {
      return _ifStatement(builder, parent, statement);
    } else if (statement is WhileStatement) {
      return _whileStatement(builder, statement);
    } else if (parent is WhileStatement) {
      return _whileStatement(builder, parent);
    }
  }

  Future<void> _doStatement(ChangeBuilder builder, DoStatement node) async {
    var body = node.body;
    if (body is Block) return null;

    var prefix = utils.getLinePrefix(node.offset);
    var indent = prefix + utils.getIndent(1);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.endStart(node.doKeyword, body),
        ' {$eol$indent',
      );
      builder.addSimpleReplacement(
        range.endStart(body, node.whileKeyword),
        '$eol$prefix} ',
      );
    });
  }

  Future<void> _forStatement(ChangeBuilder builder, ForStatement node) async {
    var body = node.body;
    if (body is Block) return null;

    var prefix = utils.getLinePrefix(node.offset);
    var indent = prefix + utils.getIndent(1);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.endStart(node.rightParenthesis, body),
        ' {$eol$indent',
      );
      builder.addSimpleInsertion(body.end, '$eol$prefix}');
    });
  }

  Future<void> _ifStatement(
      ChangeBuilder builder, IfStatement node, Statement thenOrElse) async {
    var prefix = utils.getLinePrefix(node.offset);
    var indent = prefix + utils.getIndent(1);

    await builder.addDartFileEdit(file, (builder) {
      var thenStatement = node.thenStatement;
      if (thenStatement is! Block &&
          (thenOrElse == null || thenOrElse == thenStatement)) {
        builder.addSimpleReplacement(
          range.endStart(node.rightParenthesis, thenStatement),
          ' {$eol$indent',
        );
        if (node.elseKeyword != null) {
          builder.addSimpleReplacement(
            range.endStart(thenStatement, node.elseKeyword),
            '$eol$prefix} ',
          );
        } else {
          builder.addSimpleInsertion(thenStatement.end, '$eol$prefix}');
        }
      }

      var elseStatement = node.elseStatement;
      if (elseStatement != null &&
          elseStatement is! Block &&
          (thenOrElse == null || thenOrElse == elseStatement)) {
        builder.addSimpleReplacement(
          range.endStart(node.elseKeyword, elseStatement),
          ' {$eol$indent',
        );
        builder.addSimpleInsertion(elseStatement.end, '$eol$prefix}');
      }
    });
  }

  Future<void> _whileStatement(
      ChangeBuilder builder, WhileStatement node) async {
    var body = node.body;
    if (body is Block) return null;

    var prefix = utils.getLinePrefix(node.offset);
    var indent = prefix + utils.getIndent(1);

    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.endStart(node.rightParenthesis, body),
        ' {$eol$indent',
      );
      builder.addSimpleInsertion(body.end, '$eol$prefix}');
    });
  }

  /// Return an instance of this class. Used as a tear-off in `FixProcessor`.
  static UseCurlyBraces newInstance() => UseCurlyBraces();
}
