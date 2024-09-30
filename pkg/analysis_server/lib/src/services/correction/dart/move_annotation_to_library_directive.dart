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
  MoveAnnotationToLibraryDirective({required super.context});

  @override
  CorrectionApplicability get applicability =>
      // TODO(applicability): comment on why.
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => DartFixKind.MOVE_ANNOTATION_TO_LIBRARY_DIRECTIVE;

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

    var firstDirective = compilationUnit.directives.isEmpty
        ? null
        : compilationUnit.directives.first;
    if (firstDirective is LibraryDirective) {
      await _moveToExistingLibraryDirective(
          builder, annotation, firstDirective);
      return;
    }

    if (!libraryElement2.featureSet.isEnabled(Feature.unnamedLibraries)) {
      // If the library doesn't support unnamed libraries, then we cannot add
      // a new library directive; we don't know what to name it.
      return;
    }

    await _moveToNewLibraryDirective(builder, annotation, compilationUnit);
  }

  Future<void> _moveToExistingLibraryDirective(ChangeBuilder builder,
      Annotation annotation, LibraryDirective libraryDirective) async {
    // Just move the annotation to the existing library directive.
    var annotationRange = utils.getLinesRange(range.node(annotation));
    await builder.addDartFileEdit(file, (builder) {
      builder.addDeletion(annotationRange);
      var annotationText = utils.getRangeText(annotationRange);
      builder.addSimpleInsertion(
          libraryDirective.firstTokenAfterCommentAndMetadata.offset,
          annotationText);
    });
  }

  Future<void> _moveToNewLibraryDirective(ChangeBuilder builder,
      Annotation annotation, CompilationUnit compilationUnit) async {
    var annotationRange = utils.getLinesRange(range.node(annotation));
    // Create a new, unnamed library directive, and move the annotation to just
    // above the directive.
    var token = compilationUnit.beginToken;

    if (token.type == TokenType.SCRIPT_TAG) {
      // TODO(srawlins): Handle this case.
      return;
    }

    if (token == annotation.beginToken) {
      // Do not "move" the annotation. Just slip a library directive below it.
      await builder.addDartFileEdit(file, (builder) {
        builder.addSimpleInsertion(annotationRange.end, 'library;$eol$eol');
      });
      return;
    }

    int insertionOffset;
    String prefix;
    Token? commentOnFirstToken = token.precedingComments;
    if (commentOnFirstToken != null) {
      while (commentOnFirstToken!.next != null) {
        commentOnFirstToken = commentOnFirstToken.next!;
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
      builder.addDeletion(annotationRange);
      var annotationText = utils.getRangeText(annotationRange);
      builder.addSimpleInsertion(
          insertionOffset, '$prefix${annotationText}library;$eol$eol');
    });
  }
}
