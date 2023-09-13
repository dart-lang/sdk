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
    // TODO(srawlins): Validate format of each parameter. For example, an
    // animation directive's width must be an int, a youtube directive's URL
    // must be a valid YouTube URL, etc.

    var positionalArgumentCount = docDirective.positionalArguments.length;
    var required = docDirective.type.positionalParameters;
    var requiredCount = docDirective.type.positionalParameters.length;

    if (positionalArgumentCount < requiredCount) {
      var gap = requiredCount - positionalArgumentCount;
      if (gap == 1) {
        _errorReporter.reportErrorForOffset(
          WarningCode.DOC_DIRECTIVE_MISSING_ONE_ARGUMENT,
          docDirective.offset,
          docDirective.end - docDirective.offset,
          [docDirective.type.name, required.last],
        );
      } else if (gap == 2) {
        var missingArguments = [
          required[required.length - 2],
          required.last,
        ];
        _errorReporter.reportErrorForOffset(
          WarningCode.DOC_DIRECTIVE_MISSING_TWO_ARGUMENTS,
          docDirective.offset,
          docDirective.end - docDirective.offset,
          [docDirective.type.name, ...missingArguments],
        );
      } else if (gap == 3) {
        var missingArguments = [
          required[required.length - 3],
          required[required.length - 2],
          required.last,
        ];
        _errorReporter.reportErrorForOffset(
          WarningCode.DOC_DIRECTIVE_MISSING_THREE_ARGUMENTS,
          docDirective.offset,
          docDirective.end - docDirective.offset,
          [docDirective.type.name, ...missingArguments],
        );
      }
    }

    if (docDirective.type.restParametersAllowed) {
      // TODO(srawlins): We probably want to enforce that at least one argument
      // is given, particularly for 'category' and 'subCategory'.
      return;
    }

    if (positionalArgumentCount > requiredCount) {
      var errorOffset = docDirective.positionalArguments[requiredCount].offset;
      var errorLength = docDirective.positionalArguments.last.end - errorOffset;
      _errorReporter.reportErrorForOffset(
        WarningCode.DOC_DIRECTIVE_HAS_EXTRA_ARGUMENTS,
        errorOffset,
        errorLength,
        [docDirective.type.name, positionalArgumentCount, requiredCount],
      );
    }

    for (var namedArgument in docDirective.namedArguments) {
      if (!docDirective.type.namedParameters.contains(namedArgument.name)) {
        _errorReporter.reportErrorForOffset(
          WarningCode.DOC_DIRECTIVE_HAS_UNEXPECTED_NAMED_ARGUMENT,
          namedArgument.offset,
          namedArgument.end - namedArgument.offset,
          [docDirective.type.name, namedArgument.name],
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
