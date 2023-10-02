// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analyzer/dart/ast/doc_comment.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/error/codes.g.dart';

/// Verifies various data parsed in doc comments.
class DocCommentVerifier {
  final ErrorReporter _errorReporter;

  DocCommentVerifier(this._errorReporter);

  void docDirective(DocDirective docDirective) {
    switch (docDirective) {
      case SimpleDocDirective():
        docDirectiveTag(docDirective.tag);
      case BlockDocDirective(:var openingTag, :var closingTag):
        docDirectiveTag(openingTag);
        if (closingTag != null) {
          docDirectiveTag(closingTag);
        }
    }
  }

  void docDirectiveTag(DocDirectiveTag tag) {
    validateArgumentCount(tag);
    validateArgumentFormat(tag);
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

  void validateArgumentCount(DocDirectiveTag tag) {
    var positionalArgumentCount = tag.positionalArguments.length;
    var required = tag.type.positionalParameters;
    var requiredCount = tag.type.positionalParameters.length;

    if (positionalArgumentCount < requiredCount) {
      var gap = requiredCount - positionalArgumentCount;
      if (gap == 1) {
        _errorReporter.reportErrorForOffset(
          WarningCode.DOC_DIRECTIVE_MISSING_ONE_ARGUMENT,
          tag.offset,
          tag.end - tag.offset,
          [tag.type.name, required.last.name],
        );
      } else if (gap == 2) {
        var missingArguments = [
          required[required.length - 2].name,
          required.last.name,
        ];
        _errorReporter.reportErrorForOffset(
          WarningCode.DOC_DIRECTIVE_MISSING_TWO_ARGUMENTS,
          tag.offset,
          tag.end - tag.offset,
          [tag.type.name, ...missingArguments],
        );
      } else if (gap == 3) {
        var missingArguments = [
          required[required.length - 3].name,
          required[required.length - 2].name,
          required.last.name,
        ];
        _errorReporter.reportErrorForOffset(
          WarningCode.DOC_DIRECTIVE_MISSING_THREE_ARGUMENTS,
          tag.offset,
          tag.end - tag.offset,
          [tag.type.name, ...missingArguments],
        );
      }
    }

    if (tag.type.restParametersAllowed) {
      // TODO(srawlins): We probably want to enforce that at least one argument
      // is given, particularly for 'category' and 'subCategory'.
      return;
    }

    if (positionalArgumentCount > requiredCount) {
      var errorOffset = tag.positionalArguments[requiredCount].offset;
      var errorLength = tag.positionalArguments.last.end - errorOffset;
      _errorReporter.reportErrorForOffset(
        WarningCode.DOC_DIRECTIVE_HAS_EXTRA_ARGUMENTS,
        errorOffset,
        errorLength,
        [tag.type.name, positionalArgumentCount, requiredCount],
      );
    }

    for (var namedArgument in tag.namedArguments) {
      if (!tag.type.namedParameters.containsNamed(namedArgument.name)) {
        _errorReporter.reportErrorForOffset(
          WarningCode.DOC_DIRECTIVE_HAS_UNEXPECTED_NAMED_ARGUMENT,
          namedArgument.offset,
          namedArgument.end - namedArgument.offset,
          [tag.type.name, namedArgument.name],
        );
      }
    }
  }

  void validateArgumentFormat(DocDirectiveTag tag) {
    var required = tag.type.positionalParameters;
    var positionalArgumentCount =
        math.min(tag.positionalArguments.length, required.length);
    for (var i = 0; i < positionalArgumentCount; i++) {
      var parameter = required[i];
      var argument = tag.positionalArguments[i];

      void reportWrongFormat() {
        _errorReporter.reportErrorForOffset(
          WarningCode.DOC_DIRECTIVE_ARGUMENT_WRONG_FORMAT,
          argument.offset,
          argument.end - argument.offset,
          [parameter.name, parameter.expectedFormat.displayString],
        );
      }

      switch (parameter.expectedFormat) {
        case DocDirectiveParameterFormat.any:
          continue;
        case DocDirectiveParameterFormat.integer:
          if (int.tryParse(argument.value) == null) {
            reportWrongFormat();
          }
        case DocDirectiveParameterFormat.uri:
          if (Uri.tryParse(argument.value) == null) {
            reportWrongFormat();
          }
        case DocDirectiveParameterFormat.youtubeUrl:
          if (Uri.tryParse(argument.value) == null ||
              !argument.value
                  .startsWith(DocDirectiveParameterFormat.youtubeUrlPrefix)) {
            reportWrongFormat();
          }
      }
    }
  }
}

extension on List<DocDirectiveParameter> {
  bool containsNamed(String name) => any((p) => p.name == name);
}
