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
  static const HintWithoutArguments
  deprecatedColonForDefaultValue = HintWithoutArguments(
    'DEPRECATED_COLON_FOR_DEFAULT_VALUE',
    "Using a colon as the separator before a default value is deprecated and "
        "will not be supported in language version 3.0 and later.",
    correctionMessage: "Try replacing the colon with an equal sign.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the name of the member
  static const HintTemplate<LocatableDiagnostic Function({required String p0})>
  deprecatedMemberUse = HintTemplate(
    'DEPRECATED_MEMBER_USE',
    "'{0}' is deprecated and shouldn't be used.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDeprecatedMemberUse,
    expectedTypes: [ExpectedType.string],
  );

  /// This code is deprecated in favor of the
  /// 'deprecated_member_from_same_package' lint rule, and will be removed.
  ///
  /// Parameters:
  /// String p0: the name of the member
  static const HintTemplate<LocatableDiagnostic Function({required String p0})>
  deprecatedMemberUseFromSamePackage = HintTemplate(
    'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE',
    "'{0}' is deprecated and shouldn't be used.",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDeprecatedMemberUseFromSamePackage,
    expectedTypes: [ExpectedType.string],
  );

  /// This code is deprecated in favor of the
  /// 'deprecated_member_from_same_package' lint rule, and will be removed.
  ///
  /// Parameters:
  /// Object p0: the name of the member
  /// Object p1: message details
  static const HintTemplate<
    LocatableDiagnostic Function({required Object p0, required Object p1})
  >
  deprecatedMemberUseFromSamePackageWithMessage = HintTemplate(
    'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE',
    "'{0}' is deprecated and shouldn't be used. {1}",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
    uniqueName: 'DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE_WITH_MESSAGE',
    withArguments: _withArgumentsDeprecatedMemberUseFromSamePackageWithMessage,
    expectedTypes: [ExpectedType.object, ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the member
  /// String p1: message details
  static const HintTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  deprecatedMemberUseWithMessage = HintTemplate(
    'DEPRECATED_MEMBER_USE',
    "'{0}' is deprecated and shouldn't be used. {1}",
    correctionMessage:
        "Try replacing the use of the deprecated member with the replacement.",
    hasPublishedDocs: true,
    uniqueName: 'DEPRECATED_MEMBER_USE_WITH_MESSAGE',
    withArguments: _withArgumentsDeprecatedMemberUseWithMessage,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// No parameters.
  static const HintWithoutArguments
  importDeferredLibraryWithLoadFunction = HintWithoutArguments(
    'IMPORT_DEFERRED_LIBRARY_WITH_LOAD_FUNCTION',
    "The imported library defines a top-level function named 'loadLibrary' "
        "that is hidden by deferring this library.",
    correctionMessage:
        "Try changing the import to not be deferred, or rename the function in "
        "the imported library.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the URI that is not necessary
  /// String p1: the URI that makes it unnecessary
  static const HintTemplate<
    LocatableDiagnostic Function({required String p0, required String p1})
  >
  unnecessaryImport = HintTemplate(
    'UNNECESSARY_IMPORT',
    "The import of '{0}' is unnecessary because all of the used elements are "
        "also provided by the import of '{1}'.",
    correctionMessage: "Try removing the import directive.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUnnecessaryImport,
    expectedTypes: [ExpectedType.string, ExpectedType.string],
  );

  /// Initialize a newly created error code to have the given [name].
  const HintCode(
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
         uniqueName: 'HintCode.${uniqueName ?? name}',
       );

  @override
  DiagnosticSeverity get severity => DiagnosticType.HINT.severity;

  @override
  DiagnosticType get type => DiagnosticType.HINT;

  static LocatableDiagnostic _withArgumentsDeprecatedMemberUse({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(deprecatedMemberUse, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedMemberUseFromSamePackage({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(deprecatedMemberUseFromSamePackage, [p0]);
  }

  static LocatableDiagnostic
  _withArgumentsDeprecatedMemberUseFromSamePackageWithMessage({
    required Object p0,
    required Object p1,
  }) {
    return LocatableDiagnosticImpl(
      deprecatedMemberUseFromSamePackageWithMessage,
      [p0, p1],
    );
  }

  static LocatableDiagnostic _withArgumentsDeprecatedMemberUseWithMessage({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(deprecatedMemberUseWithMessage, [p0, p1]);
  }

  static LocatableDiagnostic _withArgumentsUnnecessaryImport({
    required String p0,
    required String p1,
  }) {
    return LocatableDiagnosticImpl(unnecessaryImport, [p0, p1]);
  }
}

final class HintTemplate<T extends Function> extends HintCode {
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const HintTemplate(
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

final class HintWithoutArguments extends HintCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const HintWithoutArguments(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
  });
}
