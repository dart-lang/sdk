// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/ignore_comments/ignore_info.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

class RemoveIgnoredDiagnostic extends ResolvedCorrectionProducer {
  String _diagnosticName = '';
  RemoveIgnoredDiagnostic({required super.context});

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.automatically;

  @override
  List<String> get fixArguments => [_diagnosticName];

  @override
  FixKind get fixKind => DartFixKind.removeIgnoredDiagnostic;

  @override
  FixKind get multiFixKind => DartFixKind.removeIgnoredDiagnosticMulti;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var diagnostic = this.diagnostic;
    if (diagnostic == null) return;

    var diagnosticOffset = diagnostic.problemMessage.offset;

    var comment = node.commentTokenCovering(diagnosticOffset);
    if (comment is! CommentToken) return;

    var inCommentOffset = diagnosticOffset - comment.offset;

    SourceRange? rangeToDelete;

    var ignoredElements = comment.ignoredElements.toList();

    for (var (index, ignoredElement) in ignoredElements.indexed) {
      if (ignoredElement is! IgnoredDiagnosticName) continue;

      var ignoredElementOffset = ignoredElement.offset;
      if (ignoredElement.offset == diagnosticOffset) {
        _diagnosticName = ignoredElement.name;
        var scanBack = index != 0;
        var commentText = comment.lexeme;
        if (scanBack) {
          // Scan back for a preceding comma:
          for (var offset = inCommentOffset; offset > -1; --offset) {
            if (commentText[offset] == ',') {
              var backSteps = inCommentOffset - offset;
              rangeToDelete = SourceRange(
                diagnosticOffset - backSteps,
                _diagnosticName.length + backSteps,
              );
              break;
            }
          }
        } else {
          // Scan forward for a trailing comma:
          var chars = commentText.substring(inCommentOffset).indexOf(',');
          if (chars == -1) return;

          // Eat the comma
          chars++;

          // Eat a trailing space if needed
          if (commentText[inCommentOffset + chars] == ' ') chars++;

          rangeToDelete = SourceRange(ignoredElementOffset, chars);
        }
      }
    }

    if (rangeToDelete != null) {
      await builder.addDartFileEdit(file, (builder) {
        builder.addDeletion(rangeToDelete!);
      });
    }
  }
}
