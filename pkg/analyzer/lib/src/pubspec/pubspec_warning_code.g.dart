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

part of "package:analyzer/src/pubspec/pubspec_warning_code.dart";

class PubspecWarningCode extends DiagnosticCodeWithExpectedTypes {
  /// Parameters:
  /// String p0: the path to the asset directory as given in the file.
  static const PubspecWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  assetDirectoryDoesNotExist = PubspecWarningTemplate(
    'ASSET_DIRECTORY_DOES_NOT_EXIST',
    "The asset directory '{0}' doesn't exist.",
    correctionMessage:
        "Try creating the directory or fixing the path to the directory.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsAssetDirectoryDoesNotExist,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the path to the asset as given in the file.
  static const PubspecWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  assetDoesNotExist = PubspecWarningTemplate(
    'ASSET_DOES_NOT_EXIST',
    "The asset file '{0}' doesn't exist.",
    correctionMessage: "Try creating the file or fixing the path to the file.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsAssetDoesNotExist,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const PubspecWarningWithoutArguments
  assetFieldNotList = PubspecWarningWithoutArguments(
    'ASSET_FIELD_NOT_LIST',
    "The value of the 'assets' field is expected to be a list of relative file "
        "paths.",
    correctionMessage:
        "Try converting the value to be a list of relative file paths.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const PubspecWarningWithoutArguments assetMissingPath =
      PubspecWarningWithoutArguments(
        'ASSET_MISSING_PATH',
        "Asset map entry must contain a 'path' field.",
        correctionMessage: "Try adding a 'path' field.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// This code is deprecated in favor of the
  /// 'ASSET_NOT_STRING_OR_MAP' code, and will be removed.
  ///
  /// No parameters.
  static const PubspecWarningWithoutArguments assetNotString =
      PubspecWarningWithoutArguments(
        'ASSET_NOT_STRING',
        "Assets are required to be file paths (strings).",
        correctionMessage: "Try converting the value to be a string.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const PubspecWarningWithoutArguments assetNotStringOrMap =
      PubspecWarningWithoutArguments(
        'ASSET_NOT_STRING_OR_MAP',
        "An asset value is required to be a file path (string) or map.",
        correctionMessage: "Try converting the value to be a string or map.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const PubspecWarningWithoutArguments assetPathNotString =
      PubspecWarningWithoutArguments(
        'ASSET_PATH_NOT_STRING',
        "Asset paths are required to be file paths (strings).",
        correctionMessage: "Try converting the value to be a string.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the field
  static const PubspecWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  dependenciesFieldNotMap = PubspecWarningTemplate(
    'DEPENDENCIES_FIELD_NOT_MAP',
    "The value of the '{0}' field is expected to be a map.",
    correctionMessage: "Try converting the value to be a map.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDependenciesFieldNotMap,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the field
  static const PubspecWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  deprecatedField = PubspecWarningTemplate(
    'DEPRECATED_FIELD',
    "The '{0}' field is no longer used and can be removed.",
    correctionMessage: "Try removing the field.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsDeprecatedField,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const PubspecWarningWithoutArguments flutterFieldNotMap =
      PubspecWarningWithoutArguments(
        'FLUTTER_FIELD_NOT_MAP',
        "The value of the 'flutter' field is expected to be a map.",
        correctionMessage: "Try converting the value to be a map.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the kind of dependency.
  static const PubspecWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  invalidDependency = PubspecWarningTemplate(
    'INVALID_DEPENDENCY',
    "Publishable packages can't have '{0}' dependencies.",
    correctionMessage:
        "Try adding a 'publish_to: none' entry to mark the package as not for "
        "publishing or remove the {0} dependency.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsInvalidDependency,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const PubspecWarningWithoutArguments
  invalidPlatformsField = PubspecWarningWithoutArguments(
    'INVALID_PLATFORMS_FIELD',
    "The 'platforms' field must be a map with platforms as keys.",
    correctionMessage:
        "Try changing the 'platforms' field to a map with platforms as keys.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the list of packages missing from the dependencies and the list
  ///            of packages missing from the dev_dependencies (if any) in the
  ///            pubspec file.
  static const PubspecWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  missingDependency = PubspecWarningTemplate(
    'MISSING_DEPENDENCY',
    "Missing a dependency on imported package '{0}'.",
    correctionMessage: "Try adding {0}.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsMissingDependency,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const PubspecWarningWithoutArguments missingName =
      PubspecWarningWithoutArguments(
        'MISSING_NAME',
        "The 'name' field is required but missing.",
        correctionMessage: "Try adding a field named 'name'.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// No parameters.
  static const PubspecWarningWithoutArguments nameNotString =
      PubspecWarningWithoutArguments(
        'NAME_NOT_STRING',
        "The value of the 'name' field is required to be a string.",
        correctionMessage: "Try converting the value to be a string.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the path to the dependency as given in the file.
  static const PubspecWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  pathDoesNotExist = PubspecWarningTemplate(
    'PATH_DOES_NOT_EXIST',
    "The path '{0}' doesn't exist.",
    correctionMessage:
        "Try creating the referenced path or using a path that exists.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsPathDoesNotExist,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the path as given in the file.
  static const PubspecWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  pathNotPosix = PubspecWarningTemplate(
    'PATH_NOT_POSIX',
    "The path '{0}' isn't a POSIX-style path.",
    correctionMessage: "Try converting the value to a POSIX-style path.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsPathNotPosix,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the path to the dependency as given in the file.
  static const PubspecWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  pathPubspecDoesNotExist = PubspecWarningTemplate(
    'PATH_PUBSPEC_DOES_NOT_EXIST',
    "The directory '{0}' doesn't contain a pubspec.",
    correctionMessage:
        "Try creating a pubspec in the referenced directory or using a path "
        "that has a pubspec.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsPathPubspecDoesNotExist,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const PubspecWarningWithoutArguments platformValueDisallowed =
      PubspecWarningWithoutArguments(
        'PLATFORM_VALUE_DISALLOWED',
        "Keys in the `platforms` field can't have values.",
        correctionMessage: "Try removing the value, while keeping the key.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the unknown platform.
  static const PubspecWarningTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  unknownPlatform = PubspecWarningTemplate(
    'UNKNOWN_PLATFORM',
    "The platform '{0}' is not a recognized platform.",
    correctionMessage: "Try correcting the platform name or removing it.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUnknownPlatform,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the package in the dev_dependency list.
  static const PubspecWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unnecessaryDevDependency = PubspecWarningTemplate(
    'UNNECESSARY_DEV_DEPENDENCY',
    "The dev dependency on {0} is unnecessary because there is also a normal "
        "dependency on that package.",
    correctionMessage: "Try removing the dev dependency.",
    hasPublishedDocs: true,
    withArguments: _withArgumentsUnnecessaryDevDependency,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const PubspecWarningWithoutArguments
  workspaceFieldNotList = PubspecWarningWithoutArguments(
    'WORKSPACE_FIELD_NOT_LIST',
    "The value of the 'workspace' field is required to be a list of relative "
        "file paths.",
    correctionMessage:
        "Try converting the value to be a list of relative file paths.",
    hasPublishedDocs: true,
    expectedTypes: [],
  );

  /// No parameters.
  static const PubspecWarningWithoutArguments workspaceValueNotString =
      PubspecWarningWithoutArguments(
        'WORKSPACE_VALUE_NOT_STRING',
        "Workspace entries are required to be directory paths (strings).",
        correctionMessage: "Try converting the value to be a string.",
        hasPublishedDocs: true,
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the path of the directory that contains the pubspec.yaml file.
  static const PubspecWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  workspaceValueNotSubdirectory = PubspecWarningTemplate(
    'WORKSPACE_VALUE_NOT_SUBDIRECTORY',
    "Workspace values must be a relative path of a subdirectory of '{0}'.",
    correctionMessage:
        "Try using a subdirectory of the directory containing the "
        "'pubspec.yaml' file.",
    withArguments: _withArgumentsWorkspaceValueNotSubdirectory,
    expectedTypes: [ExpectedType.string],
  );

  /// Initialize a newly created error code to have the given [name].
  const PubspecWarningCode(
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
         uniqueName: 'PubspecWarningCode.${uniqueName ?? name}',
       );

  @override
  DiagnosticSeverity get severity => DiagnosticSeverity.WARNING;

  @override
  DiagnosticType get type => DiagnosticType.STATIC_WARNING;

  static LocatableDiagnostic _withArgumentsAssetDirectoryDoesNotExist({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(assetDirectoryDoesNotExist, [p0]);
  }

  static LocatableDiagnostic _withArgumentsAssetDoesNotExist({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(assetDoesNotExist, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDependenciesFieldNotMap({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(dependenciesFieldNotMap, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedField({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(deprecatedField, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvalidDependency({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(invalidDependency, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMissingDependency({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(missingDependency, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPathDoesNotExist({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(pathDoesNotExist, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPathNotPosix({required String p0}) {
    return LocatableDiagnosticImpl(pathNotPosix, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPathPubspecDoesNotExist({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(pathPubspecDoesNotExist, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnknownPlatform({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(unknownPlatform, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnnecessaryDevDependency({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(unnecessaryDevDependency, [p0]);
  }

  static LocatableDiagnostic _withArgumentsWorkspaceValueNotSubdirectory({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(workspaceValueNotSubdirectory, [p0]);
  }
}

final class PubspecWarningTemplate<T extends Function>
    extends PubspecWarningCode {
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const PubspecWarningTemplate(
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

final class PubspecWarningWithoutArguments extends PubspecWarningCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const PubspecWarningWithoutArguments(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
  });
}
