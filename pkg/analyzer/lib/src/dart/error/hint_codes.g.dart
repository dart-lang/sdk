// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// We allow some snake_case and SCREAMING_SNAKE_CASE identifiers in generated
// code, as they match names declared in the source configuration files.
// ignore_for_file: constant_identifier_names

// While transitioning `HintCodes` to `WarningCodes`, we refer to deprecated
// codes here.
// ignore_for_file: deprecated_member_use_from_same_package
//
// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

import "package:analyzer/error/error.dart";
import "package:analyzer/src/error/analyzer_error_code.dart";

class HintCode extends AnalyzerErrorCode {
  ///  No parameters.
  ///
  ///  Note: Since this diagnostic is only produced in pre-3.0 code, we do not
  ///  plan to go through the exercise of converting it to a Warning.
  static const HintCode DEPRECATED_COLON_FOR_DEFAULT_VALUE = HintCode(
    'DEPRECATED_COLON_FOR_DEFAULT_VALUE',
    "Using a colon as the separator before a default value is deprecated and "
        "will not be supported in language version 3.0 and later.",
    correctionMessage: "Try replacing the colon with an equal sign.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the member
  static const HintCode DEPRECATED_MEMBER_USE = HintCode(
    'DEPRECATED_MEMBER_USE',
    "'{0}' is deprecated and shouldn't be used.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the member
  ///
  ///  This code is deprecated in favor of the
  ///  'deprecated_member_from_same_package' lint rule, and will be removed.
  static const HintCode DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE = HintCode(
    'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE',
    "'{0}' is deprecated and shouldn't be used.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
  );

  ///  Parameters:
  ///  0: the name of the member
  ///  1: message details
  ///
  ///  This code is deprecated in favor of the
  ///  'deprecated_member_from_same_package' lint rule, and will be removed.
  static const HintCode DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE =
      HintCode(
    'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE',
    "'{0}' is deprecated and shouldn't be used. {1}",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
    uniqueName: 'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE',
  );

  ///  Parameters:
  ///  0: the name of the member
  ///  1: message details
  static const HintCode DEPRECATED_MEMBER_USE_WITH_MESSAGE = HintCode(
    'DEPRECATED_MEMBER_USE',
    "'{0}' is deprecated and shouldn't be used. {1}",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
    uniqueName: 'DEPRECATED_MEMBER_USE_WITH_MESSAGE',
  );

  ///  No parameters.
  static const HintCode IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION = HintCode(
    'IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION',
    "The imported library defines a top-level function named 'loadLibrary' "
        "that is hidden by deferring this library.",
    correctionMessage:
        "Try changing the import to not be deferred, or rename the function in "
        "the imported library.",
    hasPublishedDocs: true,
  );

  ///  Reported when the macro uses `Builder.report()` with `Severity.info`.
  ///  Parameters:
  ///  0: the message
  static const HintCode MACRO_INFO = HintCode(
    'MACRO_INFO',
    "{0}",
  );

  ///  Parameters:
  ///  0: the URI that is not necessary
  ///  1: the URI that makes it unnecessary
  static const HintCode UNNECESSARY_IMPORT = HintCode(
    'UNNECESSARY_IMPORT',
    "The import of '{0}' is unnecessary because all of the used elements are "
        "also provided by the import of '{1}'.",
    correctionMessage: "Try removing the import directive.",
    hasPublishedDocs: true,
  );

  /// Initialize a newly created error code to have the given [name].
  const HintCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
          name: name,
          problemMessage: problemMessage,
          uniqueName: 'HintCode.${uniqueName ?? name}',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorType.HINT.severity;

  @override
  ErrorType get type => ErrorType.HINT;
}
