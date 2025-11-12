// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

part of "package:analyzer/src/pubspec/pubspec_warning_code.dart";

class PubspecWarningCode {
  /// Parameters:
  /// String p0: the path to the asset directory as given in the file.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  assetDirectoryDoesNotExist = diag.assetDirectoryDoesNotExist;

  /// Parameters:
  /// String p0: the path to the asset as given in the file.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  assetDoesNotExist = diag.assetDoesNotExist;

  /// No parameters.
  static const DiagnosticWithoutArguments assetFieldNotList =
      diag.assetFieldNotList;

  /// No parameters.
  static const DiagnosticWithoutArguments assetMissingPath =
      diag.assetMissingPath;

  /// This code is deprecated in favor of the
  /// 'ASSET_NOT_STRING_OR_MAP' code, and will be removed.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments assetNotString = diag.assetNotString;

  /// No parameters.
  static const DiagnosticWithoutArguments assetNotStringOrMap =
      diag.assetNotStringOrMap;

  /// No parameters.
  static const DiagnosticWithoutArguments assetPathNotString =
      diag.assetPathNotString;

  /// Parameters:
  /// String p0: the name of the field
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  dependenciesFieldNotMap = diag.dependenciesFieldNotMap;

  /// Parameters:
  /// String p0: the name of the field
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  deprecatedField = diag.deprecatedField;

  /// No parameters.
  static const DiagnosticWithoutArguments flutterFieldNotMap =
      diag.flutterFieldNotMap;

  /// Parameters:
  /// String p0: the kind of dependency.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  invalidDependency = diag.invalidDependency;

  /// No parameters.
  static const DiagnosticWithoutArguments invalidPlatformsField =
      diag.invalidPlatformsField;

  /// Parameters:
  /// String p0: the list of packages missing from the dependencies and the list
  ///            of packages missing from the dev_dependencies (if any) in the
  ///            pubspec file.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  missingDependency = diag.missingDependency;

  /// No parameters.
  static const DiagnosticWithoutArguments missingName = diag.missingName;

  /// No parameters.
  static const DiagnosticWithoutArguments nameNotString = diag.nameNotString;

  /// Parameters:
  /// String p0: the path to the dependency as given in the file.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  pathDoesNotExist = diag.pathDoesNotExist;

  /// Parameters:
  /// String p0: the path as given in the file.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  pathNotPosix = diag.pathNotPosix;

  /// Parameters:
  /// String p0: the path to the dependency as given in the file.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  pathPubspecDoesNotExist = diag.pathPubspecDoesNotExist;

  /// No parameters.
  static const DiagnosticWithoutArguments platformValueDisallowed =
      diag.platformValueDisallowed;

  /// Parameters:
  /// Object p0: the unknown platform.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  unknownPlatform = diag.unknownPlatform;

  /// Parameters:
  /// String p0: the name of the package in the dev_dependency list.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  unnecessaryDevDependency = diag.unnecessaryDevDependency;

  /// No parameters.
  static const DiagnosticWithoutArguments workspaceFieldNotList =
      diag.workspaceFieldNotList;

  /// No parameters.
  static const DiagnosticWithoutArguments workspaceValueNotString =
      diag.workspaceValueNotString;

  /// Parameters:
  /// String p0: the path of the directory that contains the pubspec.yaml file.
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  workspaceValueNotSubdirectory = diag.workspaceValueNotSubdirectory;

  /// Do not construct instances of this class.
  PubspecWarningCode._() : assert(false);
}
