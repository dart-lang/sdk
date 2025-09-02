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

part of "package:_fe_analyzer_shared/src/scanner/errors.dart";

class ScannerErrorCode extends DiagnosticCodeWithExpectedTypes {
  /// Parameters:
  /// String p0: the token that was expected but not found
  static const ScannerErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  expectedToken = const ScannerErrorTemplate(
    'EXPECTED_TOKEN',
    "Expected to find '{0}'.",
    withArguments: _withArgumentsExpectedToken,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// Object p0: the illegal character
  static const ScannerErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  illegalCharacter = const ScannerErrorTemplate(
    'ILLEGAL_CHARACTER',
    "Illegal character '{0}'.",
    withArguments: _withArgumentsIllegalCharacter,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const ScannerErrorWithoutArguments missingDigit =
      const ScannerErrorWithoutArguments(
        'MISSING_DIGIT',
        "Decimal digit expected.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ScannerErrorWithoutArguments missingHexDigit =
      const ScannerErrorWithoutArguments(
        'MISSING_HEX_DIGIT',
        "Hexadecimal digit expected.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ScannerErrorWithoutArguments missingIdentifier =
      const ScannerErrorWithoutArguments(
        'MISSING_IDENTIFIER',
        "Expected an identifier.",
        expectedTypes: [],
      );

  /// No parameters.
  static const ScannerErrorWithoutArguments missingQuote =
      const ScannerErrorWithoutArguments(
        'MISSING_QUOTE',
        "Expected quote (' or \").",
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the path of the file that cannot be read
  static const ScannerErrorTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unableGetContent = const ScannerErrorTemplate(
    'UNABLE_GET_CONTENT',
    "Unable to get content of '{0}'.",
    withArguments: _withArgumentsUnableGetContent,
    expectedTypes: [ExpectedType.object],
  );

  /// No parameters.
  static const ScannerErrorWithoutArguments
  unexpectedDollarInString = const ScannerErrorWithoutArguments(
    'UNEXPECTED_DOLLAR_IN_STRING',
    "A '\$' has special meaning inside a string, and must be followed by an "
        "identifier or an expression in curly braces ({}).",
    correctionMessage: "Try adding a backslash (\\) to escape the '\$'.",
    expectedTypes: [],
  );

  /// No parameters.
  static const ScannerErrorWithoutArguments
  unexpectedSeparatorInNumber = const ScannerErrorWithoutArguments(
    'UNEXPECTED_SEPARATOR_IN_NUMBER',
    "Digit separators ('_') in a number literal can only be placed between two "
        "digits.",
    correctionMessage: "Try removing the '_'.",
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the unsupported operator
  static const ScannerErrorTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unsupportedOperator = const ScannerErrorTemplate(
    'UNSUPPORTED_OPERATOR',
    "The '{0}' operator is not supported.",
    withArguments: _withArgumentsUnsupportedOperator,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const ScannerErrorWithoutArguments unterminatedMultiLineComment =
      const ScannerErrorWithoutArguments(
        'UNTERMINATED_MULTI_LINE_COMMENT',
        "Unterminated multi-line comment.",
        correctionMessage:
            "Try terminating the comment with '*/', or removing any unbalanced "
            "occurrences of '/*' (because comments nest in Dart).",
        expectedTypes: [],
      );

  /// No parameters.
  static const ScannerErrorWithoutArguments unterminatedStringLiteral =
      const ScannerErrorWithoutArguments(
        'UNTERMINATED_STRING_LITERAL',
        "Unterminated string literal.",
        expectedTypes: [],
      );

  /// Initialize a newly created error code to have the given [name].
  const ScannerErrorCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
    required super.expectedTypes,
  }) : super(
         name: name,
         problemMessage: problemMessage,
         uniqueName: 'ScannerErrorCode.${uniqueName ?? name}',
       );

  @override
  DiagnosticSeverity get severity => DiagnosticType.SYNTACTIC_ERROR.severity;

  @override
  DiagnosticType get type => DiagnosticType.SYNTACTIC_ERROR;

  static LocatableDiagnostic _withArgumentsExpectedToken({required String p0}) {
    return new LocatableDiagnosticImpl(expectedToken, [p0]);
  }

  static LocatableDiagnostic _withArgumentsIllegalCharacter({
    required Object p0,
  }) {
    return new LocatableDiagnosticImpl(illegalCharacter, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnableGetContent({
    required Object p0,
  }) {
    return new LocatableDiagnosticImpl(unableGetContent, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnsupportedOperator({
    required String p0,
  }) {
    return new LocatableDiagnosticImpl(unsupportedOperator, [p0]);
  }
}

final class ScannerErrorTemplate<T extends Function> extends ScannerErrorCode {
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const ScannerErrorTemplate(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
    required this.withArguments,
  });
}

final class ScannerErrorWithoutArguments extends ScannerErrorCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const ScannerErrorWithoutArguments(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
  });
}
