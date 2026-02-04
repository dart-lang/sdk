// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class RemoveComment extends ResolvedCorrectionProducer {
  RemoveComment({required super.context});

  factory RemoveComment.ignore({required CorrectionProducerContext context}) =>
      _RemoveIgnoreComment(context: context);

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.removeComment;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var diagnostic = this.diagnostic;
    if (diagnostic == null) return;

    var diagnosticOffset = diagnostic.problemMessage.offset;

    var comment = node.commentTokenCovering(diagnosticOffset);
    if (comment is! CommentToken) return;

    await builder.addDartFileEdit(file, (builder) {
      var start = utils.getLineContentStart(comment.offset);
      var end = utils.getLineContentEnd(comment.end);
      var nextLine = utils.getLineNext(comment.end);
      if (nextLine != end) {
        // Preserve indent if there is more on the line after the comment.
        start = comment.offset;
      } else if (start != utils.getLineThis(comment.offset)) {
        // Preserve newline if there is more on the line before the comment.
        end -= utils.endOfLine.length;
      }
      builder.addDeletion(SourceRange(start, end - start));
    });
  }
}

class _RemoveIgnoreComment extends RemoveComment {
  _RemoveIgnoreComment({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  FixKind get fixKind => DartFixKind.removeUnnecessaryIgnoreComment;

  @override
  FixKind get multiFixKind => DartFixKind.removeUnnecessaryIgnoreCommentMulti;
}
