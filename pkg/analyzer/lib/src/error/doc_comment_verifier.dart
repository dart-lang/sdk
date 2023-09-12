// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/doc_comment.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/error/codes.g.dart';

/// Verifies various data parsed in doc comments.
class DocCommentVerifier {
  final ErrorReporter _errorReporter;

  DocCommentVerifier(this._errorReporter);

  void docDirective(DocDirective docDirective) {
    var positionalArgumentCount = docDirective.positionalArguments.length;
    switch (docDirective.name) {
      case DocDirectiveName.animation:
        if (positionalArgumentCount == 0) {
          _errorReporter.reportErrorForOffset(
            WarningCode.DOC_DIRECTIVE_MISSING_THREE_ARGUMENTS,
            docDirective.offset,
            docDirective.end - docDirective.offset,
            ['animation', 'width', 'height', 'url'],
          );
          return;
        } else {
          // TODO: Validate width.
        }

        if (positionalArgumentCount == 1) {
          _errorReporter.reportErrorForOffset(
            WarningCode.DOC_DIRECTIVE_MISSING_TWO_ARGUMENTS,
            docDirective.offset,
            docDirective.end - docDirective.offset,
            ['animation', 'width', 'height'],
          );
          return;
        } else {
          // TODO(srawlins): Validate height.
        }

        if (positionalArgumentCount == 2) {
          _errorReporter.reportErrorForOffset(
            WarningCode.DOC_DIRECTIVE_MISSING_ONE_ARGUMENT,
            docDirective.offset,
            docDirective.end - docDirective.offset,
            ['animation', 'url'],
          );
        } else {
          // TODO(srawlins): Validate URL.
        }

        if (positionalArgumentCount > 3) {
          var errorOffset = docDirective.positionalArguments[3].offset;
          var errorLength =
              docDirective.positionalArguments.last.end - errorOffset;
          _errorReporter.reportErrorForOffset(
            WarningCode.DOC_DIRECTIVE_HAS_EXTRA_ARGUMENTS,
            errorOffset,
            errorLength,
            [positionalArgumentCount, 3],
          );
        }

      // TODO(srawlins): Validate `@animation` named arguments (and report
      // unknown).

      case DocDirectiveName.youtube:
        if (positionalArgumentCount == 0) {
          _errorReporter.reportErrorForOffset(
            WarningCode.DOC_DIRECTIVE_MISSING_THREE_ARGUMENTS,
            docDirective.offset,
            docDirective.end - docDirective.offset,
            ['youtube', 'width', 'height', 'url'],
          );
          return;
        } else {
          // TODO: Validate width.
        }

        if (positionalArgumentCount == 1) {
          _errorReporter.reportErrorForOffset(
            WarningCode.DOC_DIRECTIVE_MISSING_TWO_ARGUMENTS,
            docDirective.offset,
            docDirective.end - docDirective.offset,
            ['youtube', 'width', 'height'],
          );
          return;
        } else {
          // TODO(srawlins): Validate height.
        }

        if (positionalArgumentCount == 2) {
          _errorReporter.reportErrorForOffset(
            WarningCode.DOC_DIRECTIVE_MISSING_ONE_ARGUMENT,
            docDirective.offset,
            docDirective.end - docDirective.offset,
            ['youtube', 'url'],
          );
        } else {
          // TODO(srawlins): Validate URL.
        }

        if (positionalArgumentCount > 3) {
          var errorOffset = docDirective.positionalArguments[3].offset;
          var errorLength =
              docDirective.positionalArguments.last.end - errorOffset;
          _errorReporter.reportErrorForOffset(
            WarningCode.DOC_DIRECTIVE_HAS_EXTRA_ARGUMENTS,
            errorOffset,
            errorLength,
            [positionalArgumentCount, 3],
          );
        }
    }
  }

  /// Verifies doc imports, written as `@docImport`.
  void docImport(DocImport docImport) {
    var deferredKeyword = docImport.import.deferredKeyword;
    if (deferredKeyword != null) {
      _errorReporter.reportErrorForToken(
        WarningCode.DOC_IMPORT_CANNOT_BE_DEFERRED,
        deferredKeyword,
      );
    }
    var configurations = docImport.import.configurations;
    if (configurations.isNotEmpty) {
      _errorReporter.reportErrorForOffset(
        WarningCode.DOC_IMPORT_CANNOT_HAVE_CONFIGURATIONS,
        configurations.first.offset,
        configurations.last.end - configurations.first.offset,
      );
    }
  }
}
