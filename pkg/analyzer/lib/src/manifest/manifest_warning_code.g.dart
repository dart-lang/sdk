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
  'Use package:analyzer/src/manifest/manifest_warning_code.dart instead',
)
library;

import "package:_fe_analyzer_shared/src/base/errors.dart";

class ManifestWarningCode extends DiagnosticCode {
  /// A code indicating that the camera permissions is not supported on Chrome
  /// OS.
  ///
  /// No parameters.
  static const ManifestWarningCode
  cameraPermissionsIncompatible = ManifestWarningCode(
    'CAMERA_PERMISSIONS_INCOMPATIBLE',
    "Camera permissions make app incompatible for Chrome OS, consider adding "
        "optional features \"android.hardware.camera\" and "
        "\"android.hardware.camera.autofocus\".",
    correctionMessage:
        "Try adding `<uses-feature android:name=\"android.hardware.camera\"  "
        "android:required=\"false\">` `<uses-feature "
        "android:name=\"android.hardware.camera.autofocus\"  "
        "android:required=\"false\">`.",
  );

  /// A code indicating that the activity is set to be non resizable.
  ///
  /// No parameters.
  static const ManifestWarningCode nonResizableActivity = ManifestWarningCode(
    'NON_RESIZABLE_ACTIVITY',
    "The `<activity>` element should be allowed to be resized to allow users "
        "to take advantage of the multi-window environment on Chrome OS",
    correctionMessage:
        "Consider declaring the corresponding activity element with "
        "`resizableActivity=\"true\"` attribute.",
  );

  /// A code indicating that the touchscreen feature is not specified in the
  /// manifest.
  ///
  /// No parameters.
  static const ManifestWarningCode noTouchscreenFeature = ManifestWarningCode(
    'NO_TOUCHSCREEN_FEATURE',
    "The default \"android.hardware.touchscreen\" needs to be optional for "
        "Chrome OS. ",
    correctionMessage:
        "Consider adding <uses-feature "
        "android:name=\"android.hardware.touchscreen\" android:required=\"false\" "
        "/> to the manifest.",
  );

  /// A code indicating that a specified permission is not supported on Chrome
  /// OS.
  ///
  /// Parameters:
  /// Object p0: the name of the feature tag
  static const ManifestWarningCode
  permissionImpliesUnsupportedHardware = ManifestWarningCode(
    'PERMISSION_IMPLIES_UNSUPPORTED_HARDWARE',
    "Permission makes app incompatible for Chrome OS, consider adding optional "
        "{0} feature tag, ",
    correctionMessage:
        " Try adding `<uses-feature android:name=\"{0}\"  "
        "android:required=\"false\">`.",
  );

  /// A code indicating that the activity is locked to an orientation.
  ///
  /// No parameters.
  static const ManifestWarningCode
  settingOrientationOnActivity = ManifestWarningCode(
    'SETTING_ORIENTATION_ON_ACTIVITY',
    "The `<activity>` element should not be locked to any orientation so that "
        "users can take advantage of the multi-window environments and larger "
        "screens on Chrome OS",
    correctionMessage:
        "Consider declaring the corresponding activity element with "
        "`screenOrientation=\"unspecified\"` or `\"fullSensor\"` attribute.",
  );

  /// A code indicating that a specified feature is not supported on Chrome OS.
  ///
  /// Parameters:
  /// String p0: the name of the feature
  static const ManifestWarningCode unsupportedChromeOsFeature =
      ManifestWarningCode(
        'UNSUPPORTED_CHROME_OS_FEATURE',
        "The feature {0} isn't supported on Chrome OS, consider making it "
            "optional.",
        correctionMessage:
            "Try changing to `android:required=\"false\"` for this feature.",
      );

  /// A code indicating that a specified hardware feature is not supported on
  /// Chrome OS.
  ///
  /// Parameters:
  /// String p0: the name of the feature
  static const ManifestWarningCode unsupportedChromeOsHardware =
      ManifestWarningCode(
        'UNSUPPORTED_CHROME_OS_HARDWARE',
        "The feature {0} isn't supported on Chrome OS, consider making it "
            "optional.",
        correctionMessage:
            "Try adding `android:required=\"false\"` for this feature.",
      );

  /// Initialize a newly created error code to have the given [name].
  const ManifestWarningCode(
    String name,
    String problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    String? uniqueName,
  }) : super(
         name: name,
         problemMessage: problemMessage,
         uniqueName: 'ManifestWarningCode.${uniqueName ?? name}',
       );

  @override
  DiagnosticSeverity get severity => DiagnosticSeverity.WARNING;

  @override
  DiagnosticType get type => DiagnosticType.STATIC_WARNING;
}
