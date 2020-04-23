// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/error/codes.dart';

/// Instances of the class `ToDoFinder` find to-do comments in Dart code.
class TodoFinder {
  /// The error reporter by which to-do comments will be reported.
  final ErrorReporter _errorReporter;

  /// Initialize a newly created to-do finder to report to-do comments to the
  /// given reporter.
  ///
  /// @param errorReporter the error reporter by which to-do comments will be
  ///        reported
  TodoFinder(this._errorReporter);

  /// Search the comments in the given compilation unit for to-do comments and
  /// report an error for each.
  ///
  /// @param unit the compilation unit containing the to-do comments
  void findIn(CompilationUnit unit) {
    _gatherTodoComments(unit.beginToken);
  }

  /// Search the comment tokens reachable from the given token and create errors
  /// for each to-do comment.
  ///
  /// @param token the head of the list of tokens being searched
  void _gatherTodoComments(Token token) {
    while (token != null && token.type != TokenType.EOF) {
      Token commentToken = token.precedingComments;
      while (commentToken != null) {
        if (commentToken.type == TokenType.SINGLE_LINE_COMMENT ||
            commentToken.type == TokenType.MULTI_LINE_COMMENT) {
          _scrapeTodoComment(commentToken);
        }
        commentToken = commentToken.next;
      }
      token = token.next;
    }
  }

  /// Look for user defined tasks in comments and convert them into info level
  /// analysis issues.
  ///
  /// @param commentToken the comment token to analyze
  void _scrapeTodoComment(Token commentToken) {
    Iterable<Match> matches =
        TodoCode.TODO_REGEX.allMatches(commentToken.lexeme);
    for (Match match in matches) {
      int offset = commentToken.offset + match.start + match.group(1).length;
      String todoText = match.group(2);

      if (commentToken.type == TokenType.MULTI_LINE_COMMENT &&
          todoText.endsWith('*/')) {
        // Remove the `*/` and trim any trailing whitespace.
        todoText = todoText.substring(0, todoText.length - 2).trimRight();
      }

      _errorReporter.reportErrorForOffset(
          TodoCode.TODO, offset, todoText.length, [todoText]);
    }
  }
}
