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
    switch (docDirective) {
      case YouTubeDocDirective():
        var widthOffset = docDirective.widthOffset;
        var widthEnd = docDirective.widthEnd;
        if (widthOffset == null || widthEnd == null) {
          _errorReporter.reportErrorForOffset(
            WarningCode.DOC_YOUTUBE_DIRECTIVE_MISSING_WIDTH,
            docDirective.offset,
            docDirective.end - docDirective.offset,
          );
          return;
        } else {
          // TODO: Validate width.
        }

        var heightOffset = docDirective.heightOffset;
        var heightEnd = docDirective.heightEnd;
        if (heightOffset == null || heightEnd == null) {
          _errorReporter.reportErrorForOffset(
            WarningCode.DOC_YOUTUBE_DIRECTIVE_MISSING_HEIGHT,
            docDirective.offset,
            docDirective.end - docDirective.offset,
          );
          return;
        } else {
          // TODO(srawlins): Validate height.
        }

        var urlOffset = docDirective.urlOffset;
        var urlEnd = docDirective.urlEnd;
        if (urlOffset == null || urlEnd == null) {
          _errorReporter.reportErrorForOffset(
            WarningCode.DOC_YOUTUBE_DIRECTIVE_MISSING_URL,
            docDirective.offset,
            docDirective.end - docDirective.offset,
          );
        } else {
          // TODO(srawlins): Validate URL.
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
