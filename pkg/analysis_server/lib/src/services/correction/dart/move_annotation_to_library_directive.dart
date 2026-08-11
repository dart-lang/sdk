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
  Future<void> _moveToNewLibraryDirective(
    ChangeBuilder builder,
    Annotation annotation,
    CompilationUnit compilationUnit,
  ) async {
    var annotationRange = utils.getLinesRange(range.node(annotation));
    var token = compilationUnit.beginToken;

    // Do not "move" the annotation. Just slip a library directive below it.
    if (token == annotation.beginToken) {
      await builder.addDartFileEdit(file, (builder) {
        var eol = builder.eol;
        builder.addSimpleInsertion(annotationRange.end, 'library;$eol$eol');
      });
      return;
    }

    await builder.addDartFileEdit(file, (builder) {
      var eol = builder.eol;
      var insertionOffset = 0;
      var prefix = '';

      // Move past the script tag.
      if (token.type == TokenType.SCRIPT_TAG) {
        insertionOffset = token.end;
        prefix = eol;
        token = token.next!;
      }

      // Move past headers such as copyright and language-version comments.
      Token? commentOnFirstToken = token.precedingComments;
      if (commentOnFirstToken != null) {
        while (commentOnFirstToken!.next != null) {
          commentOnFirstToken = commentOnFirstToken.next!;
        }
        insertionOffset = commentOnFirstToken.end;
        prefix = '$eol$eol';
      }

      // Extend the replacement through whitespace before the next token.
      var leadingWhitespace = utils.getRangeText(
        range.startOffsetEndOffset(insertionOffset, annotation.offset),
      );
      var leadingWhitespaceLength = RegExp(r'^\s*')
          .firstMatch(leadingWhitespace)!
          .end;
      var insertionRange = range.startOffsetLength(
        insertionOffset,
        leadingWhitespaceLength,
      );

      var annotationText = utils.getRangeText(annotationRange);
      var replacement = '$prefix${annotationText}library;$eol$eol';
      builder.addDeletion(annotationRange);
      builder.addSimpleReplacement(insertionRange, replacement);
    });
  }
}
