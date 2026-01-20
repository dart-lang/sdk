// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analyzer/dart/ast/doc_comment.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/error/listener.dart';

/// Verifies various data parsed in doc comments.
class DocCommentVerifier {
  final DiagnosticReporter _diagnosticReporter;

  DocCommentVerifier(this._diagnosticReporter);

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
      _diagnosticReporter.report(
        diag.docImportCannotBeDeferred.at(deferredKeyword),
      );
    }
    var configurations = docImport.import.configurations;
    if (configurations.isNotEmpty) {
      _diagnosticReporter.report(
        diag.docImportCannotHaveConfigurations.atOffset(
          offset: configurations.first.offset,
          length: configurations.last.end - configurations.first.offset,
        ),
      );
    }

    // TODO(srawlins): Support combinators.
    var combinators = docImport.import.combinators;
    if (combinators.isNotEmpty) {
      _diagnosticReporter.report(
        diag.docImportCannotHaveCombinators.atOffset(
          offset: combinators.first.offset,
          length: combinators.last.end - combinators.first.offset,
        ),
      );
    }

    // TODO(srawlins): Support prefixes. This was done temporarily with
    // https://dart-review.googlesource.com/c/sdk/+/387861, but this was
    // reverted as it increased memory usage.
    var prefix = docImport.import.prefix;
    if (prefix != null) {
      _diagnosticReporter.report(
        diag.docImportCannotHavePrefix.atOffset(
          offset: prefix.offset,
          length: prefix.end - prefix.offset,
        ),
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
        _diagnosticReporter.report(
          diag.docDirectiveMissingOneArgument
              .withArguments(
                directive: tag.type.name,
                argumentName: required.last.name,
              )
              .atOffset(offset: tag.offset, length: tag.end - tag.offset),
        );
      } else if (gap == 2) {
        _diagnosticReporter.report(
          diag.docDirectiveMissingTwoArguments
              .withArguments(
                directive: tag.type.name,
                argument1: required[required.length - 2].name,
                argument2: required.last.name,
              )
              .atOffset(offset: tag.offset, length: tag.end - tag.offset),
        );
      } else if (gap == 3) {
        _diagnosticReporter.report(
          diag.docDirectiveMissingThreeArguments
              .withArguments(
                directive: tag.type.name,
                argument1: required[required.length - 3].name,
                argument2: required[required.length - 2].name,
                argument3: required.last.name,
              )
              .atOffset(offset: tag.offset, length: tag.end - tag.offset),
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
      _diagnosticReporter.report(
        diag.docDirectiveHasExtraArguments
            .withArguments(
              directive: tag.type.name,
              actualCount: positionalArgumentCount,
              expectedCount: requiredCount,
            )
            .atOffset(offset: errorOffset, length: errorLength),
      );
    }

    for (var namedArgument in tag.namedArguments) {
      if (!tag.type.namedParameters.containsNamed(namedArgument.name)) {
        _diagnosticReporter.report(
          diag.docDirectiveHasUnexpectedNamedArgument
              .withArguments(
                directive: tag.type.name,
                argumentName: namedArgument.name,
              )
              .atOffset(
                offset: namedArgument.offset,
                length: namedArgument.end - namedArgument.offset,
              ),
        );
      }
    }
  }

  void validateArgumentFormat(DocDirectiveTag tag) {
    var required = tag.type.positionalParameters;
    var positionalArgumentCount = math.min(
      tag.positionalArguments.length,
      required.length,
    );
    for (var i = 0; i < positionalArgumentCount; i++) {
      var parameter = required[i];
      var argument = tag.positionalArguments[i];

      void reportWrongFormat() {
        _diagnosticReporter.report(
          diag.docDirectiveArgumentWrongFormat
              .withArguments(
                argumentName: parameter.name,
                expectedFormat: parameter.expectedFormat.displayString,
              )
              .atOffset(
                offset: argument.offset,
                length: argument.end - argument.offset,
              ),
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
              !argument.value.startsWith(
                DocDirectiveParameterFormat.youtubeUrlPrefix,
              )) {
            reportWrongFormat();
          }
      }
    }
  }
}

extension on List<DocDirectiveParameter> {
  bool containsNamed(String name) => any((p) => p.name == name);
}
