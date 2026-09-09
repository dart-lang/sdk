// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

class MoveAnnotationToLibraryDirective extends ResolvedCorrectionProducer {
  new({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.moveAnnotationToLibraryDirective;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    var annotation = node.thisOrAncestorOfType<Annotation>();
    if (annotation == null) {
      return;
    }
    var compilationUnit = annotation.root;
    if (compilationUnit is! CompilationUnit) {
      return;
    }

    var firstDirective = compilationUnit.directives.firstOrNull;
    if (firstDirective is LibraryDirective) {
      await _moveToExistingLibraryDirective(
        builder,
        annotation,
        firstDirective,
      );
      return;
    }

    if (!isEnabled(Feature.unnamedLibraries)) {
      // If the library doesn't support unnamed libraries, then we cannot add
      // a new library directive; we don't know what to name it.
      return;
    }

    await _moveToNewLibraryDirective(builder, annotation, compilationUnit);
  }

  /// Returns the location after a script tag and file-header comments, but
  /// before the content at [contentOffset].
  ({bool afterHeaderComment, int offset}) _insertionLocationBefore(
    int contentOffset,
  ) {
    var token = unitResult.unit.beginToken;
    var insertionOffset = 0;
    if (token.type == TokenType.SCRIPT_TAG) {
      insertionOffset = token.end;
      token = token.next!;
    }

    Token? lastHeaderComment;
    for (
      Token? comment = token.precedingComments;
      comment != null;
      comment = comment.next
    ) {
      if (comment.end <= contentOffset) {
        lastHeaderComment = comment;
      }
    }
    if (lastHeaderComment != null) {
      return (afterHeaderComment: true, offset: lastHeaderComment.end);
    }
    return (afterHeaderComment: false, offset: insertionOffset);
  }

  Future<void> _moveFirstDirectiveAnnotations(
    ChangeBuilder builder,
    Directive firstDirective,
  ) async {
    var diagnosticCode = diagnostic?.diagnosticCode;
    if (diagnosticCode == null) {
      return;
    }

    var diagnostics = unitResult.diagnostics.where(
      (diagnostic) => diagnostic.diagnosticCode == diagnosticCode,
    );

    // Move annotations that the lint identified as library annotations.
    // `@deprecated` is not reported because it has no explicit target, but on
    // the first directive it implicitly applies to the library.
    var annotations = firstDirective.metadata.where((annotation) {
      return annotation.elementAnnotation?.isDeprecated == true ||
          diagnostics.any(
            (diagnostic) =>
                diagnostic.offset == annotation.offset &&
                diagnostic.length == annotation.length,
          );
    }).toList();
    if (annotations.isEmpty) {
      return;
    }

    // Keep the documentation comment on the library side of the insertion.
    var firstContentOffset = annotations.first.offset;
    if (firstDirective.documentationComment case var documentationComment?) {
      if (documentationComment.offset < firstContentOffset) {
        firstContentOffset = documentationComment.offset;
      }
    }
    var insertionLocation = _insertionLocationBefore(firstContentOffset);

    var regionRange = range.startOffsetEndOffset(
      insertionLocation.offset,
      firstDirective.firstTokenAfterCommentAndMetadata.offset,
    );
    var regionText = utils.getRangeText(regionRange);

    // Move the library documentation together with its annotations. Line
    // ranges can overlap when documentation and metadata are adjacent, so
    // merge them before extracting or removing their text.
    var contentRanges = annotations
        .map((annotation) => utils.getLinesRange(range.node(annotation)))
        .toList();
    if (firstDirective.documentationComment case var documentationComment?) {
      contentRanges.add(utils.getLinesRange(range.node(documentationComment)));
    }
    contentRanges.sort((a, b) => a.offset.compareTo(b.offset));
    for (var i = contentRanges.length - 1; i > 0; i--) {
      var previous = contentRanges[i - 1];
      var current = contentRanges[i];
      if (current.offset <= previous.end) {
        contentRanges[i - 1] = previous.getUnion(current);
        contentRanges.removeAt(i);
      }
    }
    var contentText = contentRanges.map(utils.getRangeText).join();

    // Preserve everything in the region that is still attached to the first
    // directive, including annotations with non-library targets.
    var remainingText = StringBuffer();
    var offset = regionRange.offset;
    for (var contentRange in contentRanges) {
      remainingText.write(
        utils.getRangeText(
          range.startOffsetEndOffset(offset, contentRange.offset),
        ),
      );
      offset = contentRange.end;
    }
    remainingText.write(
      utils.getRangeText(range.startOffsetEndOffset(offset, regionRange.end)),
    );

    // Keep the original whitespace before the moved content, but remove the
    // same prefix from the content that remains below the new library.
    var leadingWhitespace = RegExp(r'^\s*').stringMatch(regionText)!;
    var remaining = remainingText.toString().substring(
      leadingWhitespace.length,
    );
    await builder.addDartFileEdit(file, (builder) {
      var eol = builder.eol;
      builder.addSimpleReplacement(
        regionRange,
        '$leadingWhitespace${contentText}library;$eol$eol$remaining',
      );
    });
  }

  Future<void> _moveToExistingLibraryDirective(
    ChangeBuilder builder,
    Annotation annotation,
    LibraryDirective libraryDirective,
  ) async {
    // Just move the annotation to the existing library directive.
    var annotationRange = utils.getLinesRange(range.node(annotation));
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(annotationRange);
      var annotationText = utils.getRangeText(annotationRange);
      builder.addSimpleInsertion(
        libraryDirective.firstTokenAfterCommentAndMetadata.offset,
        annotationText,
      );
    });
  }

  /// Creates a new unnamed library directive and moves [annotation]
  /// immediately above it.
  ///
  /// If [annotation] is on the first directive, also moves its library
  /// documentation and other annotations identified as library metadata,
  /// while leaving directive-specific annotations in place.
  Future<void> _moveToNewLibraryDirective(
    ChangeBuilder builder,
    Annotation annotation,
    CompilationUnit compilationUnit,
  ) async {
    if (compilationUnit.directives.firstOrNull case var firstDirective?) {
      if (firstDirective.metadata.contains(annotation)) {
        await _moveFirstDirectiveAnnotations(builder, firstDirective);
        return;
      }
    }

    var contentRange = utils.getLinesRange(range.node(annotation));
    var contentBeginToken = annotation.beginToken;
    var token = compilationUnit.beginToken;

    // The content is already in the target location.
    // Insert the library directive after it to avoid overlapping edits.
    if (token == contentBeginToken) {
      await builder.addDartFileEdit(file, (builder) {
        var eol = builder.eol;
        builder.addSimpleInsertion(contentRange.end, 'library;$eol$eol');
      });
      return;
    }

    var insertionLocation = _insertionLocationBefore(contentRange.offset);
    await builder.addDartFileEdit(file, (builder) {
      var eol = builder.eol;
      var prefix = insertionLocation.afterHeaderComment
          ? '$eol$eol'
          : insertionLocation.offset != 0
          ? eol
          : '';

      // Extend the replacement through whitespace before the next token.
      var textBeforeContent = utils.getRangeText(
        range.startOffsetEndOffset(
          insertionLocation.offset,
          contentRange.offset,
        ),
      );
      var leadingWhitespaceLength = RegExp(r'^\s*')
          .firstMatch(textBeforeContent)!
          .end;
      var insertionRange = range.startOffsetLength(
        insertionLocation.offset,
        leadingWhitespaceLength,
      );

      var contentText = utils.getRangeText(contentRange);
      var replacement = '$prefix${contentText}library;$eol$eol';
      builder.addDeletion(contentRange);
      builder.addSimpleReplacement(insertionRange, replacement);
    });
  }
}
