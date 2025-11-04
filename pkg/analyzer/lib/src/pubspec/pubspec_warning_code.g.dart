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
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  assetDirectoryDoesNotExist = PubspecWarningTemplate(
    name: 'ASSET_DIRECTORY_DOES_NOT_EXIST',
    problemMessage: "The asset directory '{0}' doesn't exist.",
    correctionMessage:
        "Try creating the directory or fixing the path to the directory.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'PubspecWarningCode.ASSET_DIRECTORY_DOES_NOT_EXIST',
    withArguments: _withArgumentsAssetDirectoryDoesNotExist,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the path to the asset as given in the file.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  assetDoesNotExist = PubspecWarningTemplate(
    name: 'ASSET_DOES_NOT_EXIST',
    problemMessage: "The asset file '{0}' doesn't exist.",
    correctionMessage: "Try creating the file or fixing the path to the file.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'PubspecWarningCode.ASSET_DOES_NOT_EXIST',
    withArguments: _withArgumentsAssetDoesNotExist,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  assetFieldNotList = PubspecWarningWithoutArguments(
    name: 'ASSET_FIELD_NOT_LIST',
    problemMessage:
        "The value of the 'assets' field is expected to be a list of relative file "
        "paths.",
    correctionMessage:
        "Try converting the value to be a list of relative file paths.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'PubspecWarningCode.ASSET_FIELD_NOT_LIST',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments assetMissingPath =
      PubspecWarningWithoutArguments(
        name: 'ASSET_MISSING_PATH',
        problemMessage: "Asset map entry must contain a 'path' field.",
        correctionMessage: "Try adding a 'path' field.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'PubspecWarningCode.ASSET_MISSING_PATH',
        expectedTypes: [],
      );

  /// This code is deprecated in favor of the
  /// 'ASSET_NOT_STRING_OR_MAP' code, and will be removed.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments assetNotString =
      PubspecWarningWithoutArguments(
        name: 'ASSET_NOT_STRING',
        problemMessage: "Assets are required to be file paths (strings).",
        correctionMessage: "Try converting the value to be a string.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'PubspecWarningCode.ASSET_NOT_STRING',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments assetNotStringOrMap =
      PubspecWarningWithoutArguments(
        name: 'ASSET_NOT_STRING_OR_MAP',
        problemMessage:
            "An asset value is required to be a file path (string) or map.",
        correctionMessage: "Try converting the value to be a string or map.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'PubspecWarningCode.ASSET_NOT_STRING_OR_MAP',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments assetPathNotString =
      PubspecWarningWithoutArguments(
        name: 'ASSET_PATH_NOT_STRING',
        problemMessage: "Asset paths are required to be file paths (strings).",
        correctionMessage: "Try converting the value to be a string.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'PubspecWarningCode.ASSET_PATH_NOT_STRING',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the name of the field
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  dependenciesFieldNotMap = PubspecWarningTemplate(
    name: 'DEPENDENCIES_FIELD_NOT_MAP',
    problemMessage: "The value of the '{0}' field is expected to be a map.",
    correctionMessage: "Try converting the value to be a map.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'PubspecWarningCode.DEPENDENCIES_FIELD_NOT_MAP',
    withArguments: _withArgumentsDependenciesFieldNotMap,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the name of the field
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  deprecatedField = PubspecWarningTemplate(
    name: 'DEPRECATED_FIELD',
    problemMessage: "The '{0}' field is no longer used and can be removed.",
    correctionMessage: "Try removing the field.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'PubspecWarningCode.DEPRECATED_FIELD',
    withArguments: _withArgumentsDeprecatedField,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments flutterFieldNotMap =
      PubspecWarningWithoutArguments(
        name: 'FLUTTER_FIELD_NOT_MAP',
        problemMessage:
            "The value of the 'flutter' field is expected to be a map.",
        correctionMessage: "Try converting the value to be a map.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'PubspecWarningCode.FLUTTER_FIELD_NOT_MAP',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the kind of dependency.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  invalidDependency = PubspecWarningTemplate(
    name: 'INVALID_DEPENDENCY',
    problemMessage: "Publishable packages can't have '{0}' dependencies.",
    correctionMessage:
        "Try adding a 'publish_to: none' entry to mark the package as not for "
        "publishing or remove the {0} dependency.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'PubspecWarningCode.INVALID_DEPENDENCY',
    withArguments: _withArgumentsInvalidDependency,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  invalidPlatformsField = PubspecWarningWithoutArguments(
    name: 'INVALID_PLATFORMS_FIELD',
    problemMessage:
        "The 'platforms' field must be a map with platforms as keys.",
    correctionMessage:
        "Try changing the 'platforms' field to a map with platforms as keys.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'PubspecWarningCode.INVALID_PLATFORMS_FIELD',
    expectedTypes: [],
  );

  /// Parameters:
  /// String p0: the list of packages missing from the dependencies and the list
  ///            of packages missing from the dev_dependencies (if any) in the
  ///            pubspec file.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  missingDependency = PubspecWarningTemplate(
    name: 'MISSING_DEPENDENCY',
    problemMessage: "Missing a dependency on imported package '{0}'.",
    correctionMessage: "Try adding {0}.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'PubspecWarningCode.MISSING_DEPENDENCY',
    withArguments: _withArgumentsMissingDependency,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments missingName =
      PubspecWarningWithoutArguments(
        name: 'MISSING_NAME',
        problemMessage: "The 'name' field is required but missing.",
        correctionMessage: "Try adding a field named 'name'.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'PubspecWarningCode.MISSING_NAME',
        expectedTypes: [],
      );

  /// No parameters.
  static const DiagnosticWithoutArguments nameNotString =
      PubspecWarningWithoutArguments(
        name: 'NAME_NOT_STRING',
        problemMessage:
            "The value of the 'name' field is required to be a string.",
        correctionMessage: "Try converting the value to be a string.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'PubspecWarningCode.NAME_NOT_STRING',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the path to the dependency as given in the file.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  pathDoesNotExist = PubspecWarningTemplate(
    name: 'PATH_DOES_NOT_EXIST',
    problemMessage: "The path '{0}' doesn't exist.",
    correctionMessage:
        "Try creating the referenced path or using a path that exists.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'PubspecWarningCode.PATH_DOES_NOT_EXIST',
    withArguments: _withArgumentsPathDoesNotExist,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the path as given in the file.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  pathNotPosix = PubspecWarningTemplate(
    name: 'PATH_NOT_POSIX',
    problemMessage: "The path '{0}' isn't a POSIX-style path.",
    correctionMessage: "Try converting the value to a POSIX-style path.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'PubspecWarningCode.PATH_NOT_POSIX',
    withArguments: _withArgumentsPathNotPosix,
    expectedTypes: [ExpectedType.string],
  );

  /// Parameters:
  /// String p0: the path to the dependency as given in the file.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  pathPubspecDoesNotExist = PubspecWarningTemplate(
    name: 'PATH_PUBSPEC_DOES_NOT_EXIST',
    problemMessage: "The directory '{0}' doesn't contain a pubspec.",
    correctionMessage:
        "Try creating a pubspec in the referenced directory or using a path "
        "that has a pubspec.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'PubspecWarningCode.PATH_PUBSPEC_DOES_NOT_EXIST',
    withArguments: _withArgumentsPathPubspecDoesNotExist,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments platformValueDisallowed =
      PubspecWarningWithoutArguments(
        name: 'PLATFORM_VALUE_DISALLOWED',
        problemMessage: "Keys in the `platforms` field can't have values.",
        correctionMessage: "Try removing the value, while keeping the key.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'PubspecWarningCode.PLATFORM_VALUE_DISALLOWED',
        expectedTypes: [],
      );

  /// Parameters:
  /// Object p0: the unknown platform.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unknownPlatform = PubspecWarningTemplate(
    name: 'UNKNOWN_PLATFORM',
    problemMessage: "The platform '{0}' is not a recognized platform.",
    correctionMessage: "Try correcting the platform name or removing it.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'PubspecWarningCode.UNKNOWN_PLATFORM',
    withArguments: _withArgumentsUnknownPlatform,
    expectedTypes: [ExpectedType.object],
  );

  /// Parameters:
  /// String p0: the name of the package in the dev_dependency list.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  unnecessaryDevDependency = PubspecWarningTemplate(
    name: 'UNNECESSARY_DEV_DEPENDENCY',
    problemMessage:
        "The dev dependency on {0} is unnecessary because there is also a normal "
        "dependency on that package.",
    correctionMessage: "Try removing the dev dependency.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'PubspecWarningCode.UNNECESSARY_DEV_DEPENDENCY',
    withArguments: _withArgumentsUnnecessaryDevDependency,
    expectedTypes: [ExpectedType.string],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments
  workspaceFieldNotList = PubspecWarningWithoutArguments(
    name: 'WORKSPACE_FIELD_NOT_LIST',
    problemMessage:
        "The value of the 'workspace' field is required to be a list of relative "
        "file paths.",
    correctionMessage:
        "Try converting the value to be a list of relative file paths.",
    hasPublishedDocs: true,
    uniqueNameCheck: 'PubspecWarningCode.WORKSPACE_FIELD_NOT_LIST',
    expectedTypes: [],
  );

  /// No parameters.
  static const DiagnosticWithoutArguments workspaceValueNotString =
      PubspecWarningWithoutArguments(
        name: 'WORKSPACE_VALUE_NOT_STRING',
        problemMessage:
            "Workspace entries are required to be directory paths (strings).",
        correctionMessage: "Try converting the value to be a string.",
        hasPublishedDocs: true,
        uniqueNameCheck: 'PubspecWarningCode.WORKSPACE_VALUE_NOT_STRING',
        expectedTypes: [],
      );

  /// Parameters:
  /// String p0: the path of the directory that contains the pubspec.yaml file.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  workspaceValueNotSubdirectory = PubspecWarningTemplate(
    name: 'WORKSPACE_VALUE_NOT_SUBDIRECTORY',
    problemMessage:
        "Workspace values must be a relative path of a subdirectory of '{0}'.",
    correctionMessage:
        "Try using a subdirectory of the directory containing the "
        "'pubspec.yaml' file.",
    uniqueNameCheck: 'PubspecWarningCode.WORKSPACE_VALUE_NOT_SUBDIRECTORY',
    withArguments: _withArgumentsWorkspaceValueNotSubdirectory,
    expectedTypes: [ExpectedType.string],
  );

  /// Initialize a newly created error code to have the given [name].
  const PubspecWarningCode({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
    required String super.uniqueNameCheck,
    required super.expectedTypes,
  }) : super(
         type: DiagnosticType.STATIC_WARNING,
         uniqueName: 'PubspecWarningCode.${uniqueName ?? name}',
       );

  static LocatableDiagnostic _withArgumentsAssetDirectoryDoesNotExist({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      PubspecWarningCode.assetDirectoryDoesNotExist,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsAssetDoesNotExist({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(PubspecWarningCode.assetDoesNotExist, [p0]);
  }

  static LocatableDiagnostic _withArgumentsDependenciesFieldNotMap({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(PubspecWarningCode.dependenciesFieldNotMap, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsDeprecatedField({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(PubspecWarningCode.deprecatedField, [p0]);
  }

  static LocatableDiagnostic _withArgumentsInvalidDependency({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(PubspecWarningCode.invalidDependency, [p0]);
  }

  static LocatableDiagnostic _withArgumentsMissingDependency({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(PubspecWarningCode.missingDependency, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPathDoesNotExist({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(PubspecWarningCode.pathDoesNotExist, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPathNotPosix({required String p0}) {
    return LocatableDiagnosticImpl(PubspecWarningCode.pathNotPosix, [p0]);
  }

  static LocatableDiagnostic _withArgumentsPathPubspecDoesNotExist({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(PubspecWarningCode.pathPubspecDoesNotExist, [
      p0,
    ]);
  }

  static LocatableDiagnostic _withArgumentsUnknownPlatform({
    required Object p0,
  }) {
    return LocatableDiagnosticImpl(PubspecWarningCode.unknownPlatform, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnnecessaryDevDependency({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      PubspecWarningCode.unnecessaryDevDependency,
      [p0],
    );
  }

  static LocatableDiagnostic _withArgumentsWorkspaceValueNotSubdirectory({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(
      PubspecWarningCode.workspaceValueNotSubdirectory,
      [p0],
    );
  }
}

final class PubspecWarningTemplate<T extends Function>
    extends PubspecWarningCode
    implements DiagnosticWithArguments<T> {
  @override
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const PubspecWarningTemplate({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.uniqueNameCheck,
    required super.expectedTypes,
    required this.withArguments,
  });
}

final class PubspecWarningWithoutArguments extends PubspecWarningCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const PubspecWarningWithoutArguments({
    required super.name,
    required super.problemMessage,
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.uniqueNameCheck,
    required super.expectedTypes,
  });
}
