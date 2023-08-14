// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class UseCurlyBraces extends ParsedCorrectionProducer {
  @override
  bool canBeAppliedInBulk;

  UseCurlyBraces() : canBeAppliedInBulk = true;

  /// Create an instance that is prevented from being applied automatically in
  /// bulk.
  ///
  /// This is used in places where "Use Curly Braces" is a valid manual fix, but
  /// not clearly the only/correct fix to apply automatically, such as the
  /// `always_put_control_body_on_new_line` lint.
  UseCurlyBraces.nonBulk() : canBeAppliedInBulk = false;

  @override
  AssistKind get assistKind => DartAssistKind.USE_CURLY_BRACES;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.ADD_CURLY_BRACES;

  @override
  FixKind get multiFixKind => DartFixKind.ADD_CURLY_BRACES_MULTI;

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
      var elseKeyword = statement.elseKeyword;
      var elseStatement = statement.elseStatement;
      if (elseKeyword != null &&
          elseStatement != null &&
          range.token(elseKeyword).contains(selectionOffset)) {
        return _ifStatement(builder, statement, elseStatement);
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
    if (body is Block) return;

    var prefix = utils.getLinePrefix(node.offset);
    var indent = prefix + utils.getIndent(1);

    await builder.addDartFileEdit(file, (builder) {
      _replaceRange(
          builder, node.doKeyword, body, node.whileKeyword, indent, prefix);
    });
  }

  int _endAfterComments(AstNode node) {
    var end = node.end;
    var comments = node.endToken.next?.precedingComments;
    if (comments != null &&
        utils.getLineThis(end) == utils.getLineThis(comments.offset)) {
      end = comments.end;
    }
    return end;
  }

  Future<void> _forStatement(ChangeBuilder builder, ForStatement node) async {
    var body = node.body;
    if (body is Block) return;

    var prefix = utils.getLinePrefix(node.offset);
    var indent = prefix + utils.getIndent(1);

    await builder.addDartFileEdit(file, (builder) {
      _replace(builder, node.rightParenthesis, body, indent, prefix);
    });
  }

  Future<void> _ifStatement(
      ChangeBuilder builder, IfStatement node, Statement? thenOrElse) async {
    final parent = node.parent;
    if (parent is IfStatement && parent.elseStatement == node) {
      return;
    }

    var prefix = utils.getLinePrefix(node.offset);
    var indent = prefix + utils.getIndent(1);

    await builder.addDartFileEdit(file, (builder) {
      var thenStatement = node.thenStatement;
      var elseKeyword = node.elseKeyword;
      if (thenStatement is! Block &&
          (thenOrElse == null || thenOrElse == thenStatement)) {
        if (elseKeyword == null) {
          _replace(
              builder, node.rightParenthesis, thenStatement, indent, prefix);
        } else {
          _replaceRange(builder, node.rightParenthesis, thenStatement,
              elseKeyword, indent, prefix);
        }
      }

      var elseStatement = node.elseStatement;
      if (elseKeyword == null || elseStatement == null) {
        return;
      }

      if (elseStatement is Block || elseStatement is IfStatement) {
        return;
      }

      if (thenOrElse == null || thenOrElse == elseStatement) {
        _replace(builder, elseKeyword, elseStatement, indent, prefix);
      }
    });
  }

  void _replace(DartFileEditBuilder builder, SyntacticEntity left,
      AstNode right, String indent, String prefix) {
    _replaceLeftParenthesis(builder, left, right, indent);

    builder.addSimpleInsertion(_endAfterComments(right), '$eol$prefix}');
  }

  void _replaceLeftParenthesis(DartFileEditBuilder builder,
      SyntacticEntity left, SyntacticEntity right, String indent) {
    // Keep any comments preceeding right.
    if (right is AstNode) {
      right = right.beginToken.precedingComments ?? right;
    }
    builder.addSimpleReplacement(
      range.endStart(left, right),
      ' {$eol$indent',
    );
  }

  void _replaceRange(DartFileEditBuilder builder, SyntacticEntity left,
      AstNode node, SyntacticEntity right, String indent, String prefix) {
    _replaceLeftParenthesis(builder, left, node, indent);

    var end = _endAfterComments(node);
    builder.addSimpleReplacement(
      SourceRange(end, right.offset - end),
      '$eol$prefix} ',
    );
  }

  Future<void> _whileStatement(
      ChangeBuilder builder, WhileStatement node) async {
    var body = node.body;
    if (body is Block) return;

    var prefix = utils.getLinePrefix(node.offset);
    var indent = prefix + utils.getIndent(1);

    await builder.addDartFileEdit(file, (builder) {
      _replace(builder, node.rightParenthesis, body, indent, prefix);
    });
  }
}
