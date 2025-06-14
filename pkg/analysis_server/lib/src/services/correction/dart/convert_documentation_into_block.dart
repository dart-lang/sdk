// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class ConvertDocumentationIntoBlock extends ResolvedCorrectionProducer {
  ConvertDocumentationIntoBlock({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  AssistKind get assistKind => DartAssistKind.convertDocumentationIntoBlock;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var comment = node.thisOrAncestorOfType<Comment>();
    if (comment == null) {
      return;
    }
    var tokens = comment.tokens;
    if (tokens.isEmpty ||
        tokens.any(
          (Token token) =>
              token is! DocumentationCommentToken ||
              token.type != TokenType.SINGLE_LINE_COMMENT,
        )) {
      return;
    }
    var prefix = utils.getNodePrefix(comment);

    await builder.addDartFileEdit(file, (builder) {
      builder.addReplacement(range.node(comment), (builder) {
        builder.writeln('/**');
        for (var token in comment.tokens) {
          builder.write(prefix);
          builder.write(' *');
          builder.writeln(token.lexeme.substring('///'.length));
        }
        builder.write(prefix);
        builder.write(' */');
      });
    });
  }
}
