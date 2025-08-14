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
  'Use package:analyzer/src/dart/error/hint_codes.dart instead',
)
library;

import "package:_fe_analyzer_shared/src/base/errors.dart";

class HintCode extends DiagnosticCode {
  /// Note: Since this diagnostic is only produced in pre-3.0 code, we do not
  /// plan to go through the exercise of converting it to a Warning.
  ///
  /// No parameters.
  static const HintCode deprecatedColonForDefaultValue = HintCode(
    'DEPRECATED_COLON_FOR_DEFAULT_VALUE',
    "Using a colon as the separator before a default value is deprecated and "
        "will not be supported in language version 3.0 and later.",
    correctionMessage: "Try replacing the colon with an equal sign.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// String p0: the name of the member
  static const HintCode deprecatedMemberUse = HintCode(
    'DEPRECATED_MEMBER_USE',
    "'{0}' is deprecated and shouldn't be used.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
  );

  /// This code is deprecated in favor of the
  /// 'deprecated_member_from_same_package' lint rule, and will be removed.
  ///
  /// Parameters:
  /// String p0: the name of the member
  static const HintCode deprecatedMemberUseFromSamePackage = HintCode(
    'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE',
    "'{0}' is deprecated and shouldn't be used.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
  );

  /// This code is deprecated in favor of the
  /// 'deprecated_member_from_same_package' lint rule, and will be removed.
  ///
  /// Parameters:
  /// Object p0: the name of the member
  /// Object p1: message details
  static const HintCode
  deprecatedMemberUseFromSamePackageWithMessage = HintCode(
    'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE',
    "'{0}' is deprecated and shouldn't be used. {1}",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
    uniqueName: 'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE',
  );

  /// Parameters:
  /// String p0: the name of the member
  /// String p1: message details
  static const HintCode deprecatedMemberUseWithMessage = HintCode(
    'DEPRECATED_MEMBER_USE',
    "'{0}' is deprecated and shouldn't be used. {1}",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
    uniqueName: 'DEPRECATED_MEMBER_USE_WITH_MESSAGE',
  );

  /// No parameters.
  static const HintCode importDeferredLibraryWithLoadFunction = HintCode(
    'IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION',
    "The imported library defines a top-level function named 'loadLibrary' "
        "that is hidden by deferring this library.",
    correctionMessage:
        "Try changing the import to not be deferred, or rename the function in "
        "the imported library.",
    hasPublishedDocs: true,
  );

  /// Parameters:
  /// String p0: the URI that is not necessary
  /// String p1: the URI that makes it unnecessary
  static const HintCode unnecessaryImport = HintCode(
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
  DiagnosticSeverity get severity => DiagnosticType.HINT.severity;

  @override
  DiagnosticType get type => DiagnosticType.HINT;
}
