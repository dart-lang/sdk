// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// While transitioning `HintCodes` to `WarningCodes`, we refer to deprecated
// codes here.
// ignore_for_file: deprecated_member_use_from_same_package
//
// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

/// @docImport 'package:analyzer/src/dart/error/syntactic_errors.g.dart';
/// @docImport 'package:analyzer/src/error/inference_error.dart';
@Deprecated(
  // This library is deprecated to prevent it from being accidentally imported
  // It should only be imported by the corresponding non-code-generated library
  // (which suppresses the deprecation warning using an "ignore" comment).
  'Use package:_fe_analyzer_shared/src/scanner/errors.dart instead',
)
library;

import "package:_fe_analyzer_shared/src/base/errors.dart";

class ScannerErrorCode extends DiagnosticCode {
  /// Parameters:
  /// 0: the token that was expected but not found
  static const ScannerErrorCode EXPECTED_TOKEN = const ScannerErrorCode(
    'EXPECTED_TOKEN',
    "Expected to find '{0}'.",
  );

  /// Parameters:
  /// 0: the illegal character
  static const ScannerErrorCode ILLEGAL_CHARACTER = const ScannerErrorCode(
    'ILLEGAL_CHARACTER',
    "Illegal character '{0}'.",
  );

  static const ScannerErrorCode MISSING_DIGIT = const ScannerErrorCode(
    'MISSING_DIGIT',
    "Decimal digit expected.",
  );

  static const ScannerErrorCode MISSING_HEX_DIGIT = const ScannerErrorCode(
    'MISSING_HEX_DIGIT',
    "Hexadecimal digit expected.",
  );

  static const ScannerErrorCode MISSING_IDENTIFIER = const ScannerErrorCode(
    'MISSING_IDENTIFIER',
    "Expected an identifier.",
  );

  static const ScannerErrorCode MISSING_QUOTE = const ScannerErrorCode(
    'MISSING_QUOTE',
    "Expected quote (' or \").",
  );

  /// Parameters:
  /// 0: the path of the file that cannot be read
  static const ScannerErrorCode UNABLE_GET_CONTENT = const ScannerErrorCode(
    'UNABLE_GET_CONTENT',
    "Unable to get content of '{0}'.",
  );

  static const ScannerErrorCode
  UNEXPECTED_DOLLAR_IN_STRING = const ScannerErrorCode(
    'UNEXPECTED_DOLLAR_IN_STRING',
    "A '\$' has special meaning inside a string, and must be followed by an "
        "identifier or an expression in curly braces ({}).",
    correctionMessage: "Try adding a backslash (\\) to escape the '\$'.",
  );

  static const ScannerErrorCode
  UNEXPECTED_SEPARATOR_IN_NUMBER = const ScannerErrorCode(
    'UNEXPECTED_SEPARATOR_IN_NUMBER',
    "Digit separators ('_') in a number literal can only be placed between two "
        "digits.",
    correctionMessage: "Try removing the '_'.",
  );

  /// Parameters:
  /// 0: the unsupported operator
  static const ScannerErrorCode UNSUPPORTED_OPERATOR = const ScannerErrorCode(
    'UNSUPPORTED_OPERATOR',
    "The '{0}' operator is not supported.",
  );

  static const ScannerErrorCode UNTERMINATED_MULTI_LINE_COMMENT =
      const ScannerErrorCode(
        'UNTERMINATED_MULTI_LINE_COMMENT',
        "Unterminated multi-line comment.",
        correctionMessage:
            "Try terminating the comment with '*/', or removing any unbalanced "
            "occurrences of '/*' (because comments nest in Dart).",
      );

  static const ScannerErrorCode UNTERMINATED_STRING_LITERAL =
      const ScannerErrorCode(
        'UNTERMINATED_STRING_LITERAL',
        "Unterminated string literal.",
      );

  /// Initialize a newly created error code to have the given [name].
  const ScannerErrorCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
         name: name,
         problemMessage: problemMessage,
         uniqueName: 'ScannerErrorCode.${uniqueName ?? name}',
       );

  @override
  DiagnosticSeverity get severity => DiagnosticType.SYNTACTIC_ERROR.severity;

  @override
  DiagnosticType get type => DiagnosticType.SYNTACTIC_ERROR;
}
