// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:linter/src/rules/flutter_style_todos.dart';

class ConvertToFlutterStyleTodo extends ResolvedCorrectionProducer {
  ConvertToFlutterStyleTodo({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_FLUTTER_STYLE_TODO;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_FLUTTER_STYLE_TODO_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var diagnosticOffset = diagnostic?.problemMessage.offset;
    if (diagnosticOffset == null) return;

    Token? comment;

    // Find the token that follows the reported diagnostic.
    Token? token = node.beginToken;

    // First, check for a doc comment.
    if (token is CommentToken) {
      while (token != null) {
        if (token.offset == diagnosticOffset) {
          comment = token;
          break;
        }

        token = token.next;
      }
    } else {
      // Then look for the token that owns the preceding comment.
      while (token != null && token != node.endToken) {
        if (token.offset > diagnosticOffset) break;

        token = token.next;
      }
      if (token == null) return;

      comment = token.precedingComments;
      while (comment != null) {
        if (comment.offset == diagnosticOffset) break;
        comment = comment.next;
      }
    }
    if (comment == null) return;

    var content = comment.lexeme;

    // Convert doc comments.
    if (content.startsWith('///')) {
      content = content.substring(1);
    }

    // Fix unwanted leading spaces.
    var todoIndex = content.indexOf('TODO');
    if (todoIndex == -1) {
      todoIndex = content.indexOf('todo');
    }
    if (todoIndex == -1) return;

    if (todoIndex > 3) {
      // Eat white space.
      if (content.substring(3, todoIndex).trim().isEmpty) {
        content = content.replaceRange(3, todoIndex, '');
        todoIndex = 3;
      }
    }

    // Try adding a missing leading space.
    if (!content.startsWith('// ')) {
      content = content.replaceFirst('//', '// ');
    }

    // Try removing an unwanted space after `TODO`.
    if (todoIndex == 3 && content.length > 7 && content[7] == ' ') {
      content = content.replaceRange(7, 8, '');
    }

    // Try adding a colon.
    if (todoIndex == 3) {
      var colonIndex = content.indexOf(')') + 1;
      if (content.length > colonIndex && !content.startsWith(':', colonIndex)) {
        content = content.replaceFirst(')', '):');
      }
    }

    // Try fixing a lower case `todo`.
    if (content.startsWith('// todo')) {
      content = content.replaceRange(3, 7, 'TODO');
    }

    // Wrap any stray "TODO"s in message contents in ticks.
    content = content.replaceAllMapped(RegExp('TODO', caseSensitive: false), (
      match,
    ) {
      var todoText = content.substring(match.start, match.end);
      return match.start > 4 ? '`$todoText`' : todoText;
    });

    // TODO(pq): consider adding missing user info.
    // Possibly inserting '(${Platform.environment['USER'] ?? Platform.environment['USERNAME']}')
    // (assuming the environment variable is set).

    // If the generated content doesn't match flutter style, don't apply it.
    if (FlutterStyleTodos.invalidTodo(content)) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.token(comment as Token), (builder) {
        builder.write(content);
      });
    });
  }
}
