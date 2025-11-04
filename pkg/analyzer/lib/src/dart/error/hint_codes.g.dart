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

part of "package:analyzer/src/dart/error/hint_codes.dart";

class HintCode extends DiagnosticCodeWithExpectedTypes {
  /// Note: Since this diagnostic is only produced in pre-3.0 code, we do not
  /// plan to go through the exercise of converting it to a Warning.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments
  deprecatedColonForDefaultValue = HintWithoutArguments(
    name: 'DEPRECATED_COLON_FOR_DEFAULT_VALUE',
    problemMessage:
        "Using a colon as the separator before a default value is deprecated and "
        "will not be supported in language version 3.0 and later.",
    correctionMessage: "Try replacing the colon with an equal sign.",
    hasPublishedDocs: true,
    uniqueName: 'HintCode.DEPRECATED_COLON_FOR_DEFAULT_VALUE',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the member
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  deprecatedMemberUse = HintTemplate(
    name: 'DEPRECATED_MEMBER_USE',
    problemMessage: "'{0}' is deprecated and shouldn't be used.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
    uniqueName: 'HintCode.DEPRECATED_MEMBER_USE',
    withArguments: _withArgumentsDeprecatedMemberUse,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the member
  /// String p1: message details
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  deprecatedMemberUseWithMessage = HintTemplate(
    name: 'DEPRECATED_MEMBER_USE',
    problemMessage: "'{0}' is deprecated and shouldn't be used. {1}",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
    uniqueName: 'HintCode.DEPRECATED_MEMBER_USE_WITH_MESSAGE',
    withArguments: _withArgumentsDeprecatedMemberUseWithMessage,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  importDeferredLibraryWithLoadFunction = HintWithoutArguments(
    name: 'IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION',
    problemMessage:
        "The imported library defines a top-level function named 'loadLibrary' "
        "that is hidden by deferring this library.",
    correctionMessage:
        "Try changing the import to not be deferred, or rename the function in "
        "the imported library.",
    hasPublishedDocs: true,
    uniqueName: 'HintCode.IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the URI that is not necessary
  /// String p1: the URI that makes it unnecessary
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  unnecessaryImport = HintTemplate(
    name: 'UNNECESSARY_IMPORT',
    problemMessage:
        "The import of '{0}' is unnecessary because all of the used elements are "
        "also provided by the import of '{1}'.",
    correctionMessage: "Try removing the import directive.",
    hasPublishedDocs: true,
    uniqueName: 'HintCode.UNNECESSARY_IMPORT',
    withArguments: _withArgumentsUnnecessaryImport,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Initialize a newly created error code to have the given [name].
  const HintCode({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    required super.uniqueName,
    required super.expectedTypes,
  }) : super(type: DiagnosticType.HINT);

  static LocatableDiagnostic _withArgumentsDeprecatedMemberUse({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(HintCode.deprecatedMemberUse, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedMemberUseWithMessage({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(HintCode.deprecatedMemberUseWithMessage, [
      p0,
      p1,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUnnecessaryImport({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(HintCode.unnecessaryImport, [p0, p1]);
  }
}

final class HintTemplate<T extends Function> extends HintCode
    implements DiagnosticWithArguments<T> {
  @override
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const HintTemplate({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    required super.uniqueName,
    required super.expectedTypes,
    required this.withArguments,
  });
}

final class HintWithoutArguments extends HintCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const HintWithoutArguments({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    required super.uniqueName,
    required super.expectedTypes,
  });
}
