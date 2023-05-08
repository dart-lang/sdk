// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class MoveDocCommentToLibraryDirective extends CorrectionProducer {
  @override
  bool get canBeAppliedInBulk => true;

  @override
  FixKind get fixKind => DartFixKind.MOVE_DOC_COMMENT_TO_LIBRARY_DIRECTIVE;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var comment = node.thisOrAncestorOfType<Comment>();
    if (comment == null) {
      return;
    }
    var compilationUnit = comment.root;
    if (compilationUnit is! CompilationUnit) {
      return;
    }

    var firstDirective = compilationUnit.directives.firstOrNull;
    if (firstDirective is LibraryDirective) {
      await _moveToExistingLibraryDirective(builder, comment, firstDirective);
    } else if (libraryElement.featureSet.isEnabled(Feature.unnamedLibraries)) {
      await _moveToNewLibraryDirective(builder, comment, compilationUnit);
    }

    // If the library doesn't support unnamed libraries, then we cannot add
    // a new library directive; we don't know what to name it.
  }

  Future<void> _moveToExistingLibraryDirective(ChangeBuilder builder,
      Comment comment, LibraryDirective libraryDirective) async {
    // Just move the annotation to the existing library directive.
    var commentRange = utils.getLinesRange(range.node(comment));
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(commentRange);
      var commentText = utils.getRangeText(commentRange);
      builder.addSimpleInsertion(
          libraryDirective.firstTokenAfterCommentAndMetadata.offset,
          commentText);
    });
  }

  Future<void> _moveToNewLibraryDirective(ChangeBuilder builder,
      Comment comment, CompilationUnit compilationUnit) async {
    var commentRange = _rangeOfFirstBlock(comment, compilationUnit.lineInfo);

    // Create a new, unnamed library directive, and move the comment to just
    // above the directive.
    var token = compilationUnit.beginToken;

    if (token.type == TokenType.SCRIPT_TAG) {
      // TODO(srawlins): Handle this case.
      return;
    }

    if (token.precedingComments == comment.beginToken) {
      // Do not "move" the comment. Just slip a library directive below it.
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(commentRange.end, 'library;$eol');
      });
      return;
    }

    int insertionOffset;
    String prefix;
    Token? commentOnFirstToken = token.precedingComments;
    if (commentOnFirstToken != null) {
      while (commentOnFirstToken!.next != null) {
        commentOnFirstToken = commentOnFirstToken.next!;

        if (commentOnFirstToken == comment.beginToken) {
          // Do not "move" the comment. Just slip a library directive below it.
          await builder.addDartFileEdit(file, (builder) {
            builder.addSimpleInsertion(commentRange.end, 'library;$eol$eol');
          });
          return;
        }
      }
      // `token` is now the last of the leading comments (perhaps a Copyright
      // notice, a Dart language version, etc.)
      insertionOffset = commentOnFirstToken.end;
      prefix = '$eol$eol';
    } else {
      insertionOffset = 0;
      prefix = '';
    }

    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(commentRange);
      var commentText = utils.getRangeText(commentRange);
      builder.addSimpleInsertion(
          insertionOffset, '$prefix${commentText}library;$eol$eol');
    });
  }

  /// The range of the first "block" in [comment].
  ///
  /// A [Comment] can contain blank lines (even an end-of-line comment, and an
  /// end-of-line doc comment). But for the purpose of this fix, we interpret
  /// only the first "block" or "paragraph" of text as what was intented to be
  /// the library comment.
  SourceRange _rangeOfFirstBlock(Comment comment, LineInfo lineInfo) {
    for (var token in comment.tokens) {
      var next = token.next;
      if (next != null &&
          lineInfo.getLocation(next.offset).lineNumber >
              lineInfo.getLocation(token.end).lineNumber + 1) {
        // There is a blank line. Interpret this as two separate doc comments.
        return utils.getLinesRange(range.startEnd(comment.tokens.first, token));
      }
    }
    return utils.getLinesRange(range.node(comment));
  }
}
