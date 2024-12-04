// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// A correction processor that joins the `else` block of an `if` statement
/// with the inner `if` statement.
///
/// This implementation triggers only on the enclosing `else` keyword of an if
/// statement that contains an inner `if` statement.
///
/// The enclosing else block must have only one statement which is the inner
/// `if` statement.
class JoinElseWithIf extends _JoinIfWithElseBlock {
  JoinElseWithIf({required super.context})
    : super(DartAssistKind.JOIN_ELSE_WITH_IF);

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var enclosingIfStatement = node;
    if (enclosingIfStatement is! IfStatement) {
      return;
    }
    // Checks if there is an `else` keyword in the enclosing `if` statement.
    var elseKeyword = enclosingIfStatement.elseKeyword;
    if (elseKeyword == null) {
      return;
    }
    // Check if the cursor is over the `else` keyword of the enclosing `if`.
    if (elseKeyword.offset > selectionOffset ||
        elseKeyword.end < selectionEnd) {
      return;
    }
    var elseStatement = enclosingIfStatement.elseStatement;
    if (elseStatement == null) {
      return;
    }
    // Check if the enclosing else block has only one statement which is the
    // inner `if` statement.
    if (elseStatement case Block(:var statements) when statements.length == 1) {
      if (statements.first case IfStatement innerIfStatement) {
        await _compute(
          builder,
          _getStatements(innerIfStatement),
          enclosingIfStatement,
        );
      }
    }
  }
}

/// A correction processor that joins the `else` block of an `if` statement
/// with the inner `if` statement.
///
/// This implementation triggers only on the inner `if` keyword of an if
/// statement that is inside the `else` block of an enclosing `if` statement.
///
/// The enclosing else block must have only one statement which is the inner
/// `if` statement.
class JoinIfWithElse extends _JoinIfWithElseBlock {
  JoinIfWithElse({required super.context})
    : super(DartAssistKind.JOIN_IF_WITH_ELSE);

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var innerIfStatement = node;
    if (innerIfStatement is! IfStatement) {
      return;
    }
    // Check if the cursor is over the `if` keyword of the inner `if` statement.
    if (innerIfStatement.ifKeyword case var keyword
        when keyword.offset > selectionOffset || keyword.end < selectionEnd) {
      return;
    }
    var block = innerIfStatement.parent;
    IfStatement enclosingIfStatement;
    // If the parent is a block, the look for the enclosing `if` statement.
    if (block case Block(:var statements, parent: var blockParent)
        // Checks if the enclosing else block has only one statement which is
        // the inner `if` statement.
        when statements.length == 1 &&
            // This is just a precaution since it should alyways be true.
            statements.first == innerIfStatement &&
            // Checks if the parent is an `else` block of an enclosing `if`.
            blockParent is IfStatement &&
            blockParent.elseStatement == block) {
      enclosingIfStatement = blockParent;
    } else {
      return;
    }
    await _compute(
      builder,
      _getStatements(innerIfStatement),
      enclosingIfStatement,
    );
  }
}

/// A correction processor that joins the `else` block of an `if` statement
/// with the inner `if` statement.
///
/// This implements [_compute] and [_getStatements] to help the subclasses
/// with this functionality.
///
/// Here is an example:
///
/// ```dart
/// void f() {
///  if (1 == 1) {
///  } else {
///    if (2 == 2) {
///      print(0);
///    }
///  }
/// }
/// ```
///
/// Becomes:
///
/// ```dart
/// void f() {
///   if (1 == 1) {
///   } else if (2 == 2) {
///     print(0);
///   }
/// }
/// ```
abstract class _JoinIfWithElseBlock extends ResolvedCorrectionProducer {
  @override
  final AssistKind assistKind;

  _JoinIfWithElseBlock(this.assistKind, {required super.context});

  @override
  CorrectionApplicability get applicability =>
          // TODO(applicability): comment on why.
          CorrectionApplicability
          .singleLocation;

  String _blockSource(
    Block block,
    String? startCommentsSource,
    String prefix,
    String? endCommentSource,
  ) {
    var lineRanges = range.node(block);
    var blockSource = utils.getRangeText(lineRanges);
    blockSource = utils.indentSourceLeftRight(blockSource).trimRight();
    var rightBraceIndex = blockSource.lastIndexOf(
      TokenType.CLOSE_CURLY_BRACKET.lexeme,
    );
    var blockAfterRightBrace = blockSource.substring(rightBraceIndex);
    // If starting comments, insert them after the first new line.
    if (startCommentsSource != null) {
      var firstNewLine = blockSource.indexOf(eol);
      // If the block is missing new lines, add it (else).
      if (firstNewLine != -1) {
        var blockBeforeComment = blockSource.substring(0, firstNewLine);
        var blockAfterComment = blockSource.substring(
          firstNewLine,
          rightBraceIndex,
        );
        blockSource =
            '$blockBeforeComment$eol$startCommentsSource'
            '$blockAfterComment';
      } else {
        var leftBraceIndex = blockSource.indexOf(
          TokenType.OPEN_CURLY_BRACKET.lexeme,
        );
        var blockAfterComment = blockSource.substring(
          leftBraceIndex + 1,
          rightBraceIndex,
        );
        if (!blockAfterComment.startsWith('$prefix${utils.oneIndent}')) {
          blockAfterComment = '$prefix${utils.oneIndent}$blockAfterComment';
        }
        blockSource = '{$eol$startCommentsSource$eol$blockAfterComment';
      }
    } else {
      blockSource = blockSource.substring(0, rightBraceIndex);
    }
    if (endCommentSource != null) {
      blockSource = blockSource.trimRight();
      blockSource += '$eol$endCommentSource$eol$prefix';
    }
    blockSource += blockAfterRightBrace;
    return blockSource;
  }

  /// Receives the [ChangeBuilder] and the enclosing and inner `if` statements.
  /// It then joins the `else` block of the outer `if` statement with the inner
  /// `if` statement.
  Future<void> _compute(
    ChangeBuilder builder,
    List<Statement> statements,
    IfStatement outerIfStatement,
  ) async {
    var elseKeyword = outerIfStatement.elseKeyword;
    if (elseKeyword == null) {
      return;
    }
    var elseStatement = outerIfStatement.elseStatement;
    if (elseStatement == null) {
      return;
    }

    // Comments after the main `else` keyword and before the block are not
    // handled.
    if (elseStatement.beginToken.precedingComments != null) {
      return;
    }

    var prefix = utils.getNodePrefix(outerIfStatement);

    await builder.addDartFileEdit(file, (builder) {
      var source = '';
      for (var statement in statements) {
        String newBlockSource;

        source += ' else ';

        CommentToken? beforeIfKeywordComments;
        CommentToken? beforeConditionComments;
        if (statement is IfStatement) {
          beforeIfKeywordComments = statement.beginToken.precedingComments;
          beforeConditionComments = statement.ifKeyword.next?.precedingComments;
          var elseCondition = statement.expression;
          var elseConditionSource = utils.getNodeText(elseCondition);
          if (statement.caseClause case var elseCaseClause?) {
            elseConditionSource += ' ${utils.getNodeText(elseCaseClause)}';
          }
          source += 'if ($elseConditionSource) ';
          statement = statement.thenStatement;
        }

        var endingComment = statement.endToken.next?.precedingComments;
        var endCommentSource = _joinCommentsSources([
          if (endingComment case var comment?) comment,
        ], prefix);

        var beginCommentsSource = _joinCommentsSources([
          if (beforeIfKeywordComments case var comment?) comment,
          if (beforeConditionComments case var comment?) comment,
          if (statement.beginToken.precedingComments case var comment?) comment,
        ], prefix);

        if (statement case Block block) {
          newBlockSource = _blockSource(
            block,
            beginCommentsSource,
            prefix,
            endCommentSource,
          );
        } else {
          var statementSource = utils.getNodeText(statement);
          // Add indentation for the else statement if it is missing.
          if (!statementSource.startsWith(prefix)) {
            statementSource = '$prefix$statementSource';
          }
          source += '{$eol';
          if (beginCommentsSource != null) {
            source += '$beginCommentsSource$eol';
          }
          newBlockSource = '${utils.oneIndent}$statementSource';
          if (endCommentSource != null) {
            newBlockSource += '$eol$endCommentSource';
          }
          newBlockSource += '$eol$prefix}';
        }
        source += newBlockSource;
      }

      builder.addSimpleReplacement(
        range.startOffsetEndOffset(elseKeyword.offset - 1, elseStatement.end),
        source,
      );
    });
  }

  /// Returns the list of statements in the `else` block of the `if` statement.
  List<Statement> _getStatements(IfStatement innerIfStatement) {
    var elses = <Statement>[innerIfStatement];
    var currentElse = innerIfStatement.elseStatement;
    while (currentElse != null) {
      if (currentElse is IfStatement) {
        elses.add(currentElse);
        currentElse = currentElse.elseStatement;
      } else {
        elses.add(currentElse);
        break;
      }
    }
    return elses;
  }

  String? _joinCommentsSources(List<CommentToken> comments, String prefix) {
    if (comments.isEmpty) {
      return null;
    }
    String source = '';
    for (var comment in comments) {
      var commentsSource = comment.lexeme;
      var nextComment = comment.next;
      var nextCommentStart = eol + prefix + utils.oneIndent;
      while (nextComment is CommentToken) {
        commentsSource += nextCommentStart + nextComment.lexeme;
        nextComment = nextComment.next;
      }
      source = '$source$eol$commentsSource';
    }
    return '$prefix${utils.oneIndent}${source.trim()}';
  }
}
