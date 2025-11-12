// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// THIS FILE IS GENERATED. DO NOT EDIT.
//
// Instead modify 'pkg/analyzer/messages.yaml' and run
// 'dart run pkg/analyzer/tool/messages/generate.dart' to update.

// Generated comments don't quite align with flutter style.
// ignore_for_file: flutter_style_todos

part of "package:analyzer/src/manifest/manifest_warning_code.dart";

class ManifestWarningCode {
  /// A code indicating that the camera permissions is not supported on Chrome
  /// OS.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments cameraPermissionsIncompatible =
      diag.cameraPermissionsIncompatible;

  /// A code indicating that the activity is set to be non resizable.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments nonResizableActivity =
      diag.nonResizableActivity;

  /// A code indicating that the touchscreen feature is not specified in the
  /// manifest.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments noTouchscreenFeature =
      diag.noTouchscreenFeature;

  /// A code indicating that a specified permission is not supported on Chrome
  /// OS.
  ///
  /// Parameters:
  /// Object p0: the name of the feature tag
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required Object p0})
  >
  permissionImpliesUnsupportedHardware =
      diag.permissionImpliesUnsupportedHardware;

  /// A code indicating that the activity is locked to an orientation.
  ///
  /// No parameters.
  static const DiagnosticWithoutArguments settingOrientationOnActivity =
      diag.settingOrientationOnActivity;

  /// A code indicating that a specified feature is not supported on Chrome OS.
  ///
  /// Parameters:
  /// String p0: the name of the feature
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  unsupportedChromeOsFeature = diag.unsupportedChromeOsFeature;

  /// A code indicating that a specified hardware feature is not supported on
  /// Chrome OS.
  ///
  /// Parameters:
  /// String p0: the name of the feature
  static const DiagnosticWithArguments<
    LocatableDiagnostic Function({required String p0})
  >
  unsupportedChromeOsHardware = diag.unsupportedChromeOsHardware;

  /// Do not construct instances of this class.
  ManifestWarningCode._() : assert(false);
}
