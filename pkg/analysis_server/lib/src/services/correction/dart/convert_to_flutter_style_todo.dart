// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:linter/src/rules/flutter_style_todos.dart';

class ConvertToFlutterStyleTodo extends ResolvedCorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  bool get canBeAppliedToFile => true;

  @override
  FixKind get fixKind => DartFixKind.CONVERT_TO_FLUTTER_STYLE_TODO;

  @override
  FixKind get multiFixKind => DartFixKind.CONVERT_TO_FLUTTER_STYLE_TODO_MULTI;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var diagnosticOffset = diagnostic?.problemMessage.offset;
    if (diagnosticOffset == null) return;

    // Find the token that follows the reported diagnostic.
    Token? token = node.beginToken;
    while (token != null && token != node.endToken) {
      if (token.offset > diagnosticOffset) break;

      token = token.next;
    }
    if (token == null) return;

    // Identify the right comment.
    Token? comment = token.precedingComments;
    while (comment != null) {
      if (comment.offset >= diagnosticOffset) break;
      comment = comment.next;
    }
    if (comment == null) return;

    var content = comment.lexeme;

    // Fix leading spaces.
    var todoIndex = content.indexOf('TODO');
    if (todoIndex == -1) {
      todoIndex = content.indexOf('todo');
    }
    if (todoIndex == -1) return;

    if (todoIndex != 3) {
      content = content.replaceRange(2, todoIndex, ' ');
    }

    // Try adding a missing leading space before `TODO`.
    if (!content.startsWith('// ')) {
      content = content.replaceFirst('//', '// ');
    }

    // Try removing an unwanted space after `TODO`.
    if (content.length > 7 && content[7] == ' ') {
      content = content.replaceRange(7, 8, '');
    }

    // Try adding a colon.
    var index = content.indexOf(')') + 1;
    if (content.length > index && !content.startsWith(':', index)) {
      content = content.replaceFirst(')', '):');
    }

    // Try fixing lower case.
    if (content.startsWith('// todo')) {
      content = content.replaceRange(3, 7, 'TODO');
    }

    // TODO(pq): consider adding missing user info.
    // Possibly inserting '(${Platform.environment['USER'] ?? Platform.environment['USERNAME']}')
    // (assuming the environment variable is set).

    // If the generated content doesn't match flutter style, don't apply it.
    if (!content.startsWith(FlutterStyleTodos.todoExpectedRegExp)) return;

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.token(comment as Token), (builder) {
        builder.write(content);
      });
    });
  }
}
