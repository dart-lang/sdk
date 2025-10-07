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

part of "package:analyzer/src/manifest/manifest_warning_code.dart";

class ManifestWarningCode extends DiagnosticCodeWithExpectedTypes {
  /// A code indicating that the camera permissions is not supported on Chrome
  /// OS.
  ///
  /// No parameters.
  static const ManifestWarningWithoutArguments
  cameraPermissionsIncompatible = ManifestWarningWithoutArguments(
    'CAMERA_PERMISSIONS_INCOMPATIBLE',
    "Camera permissions make app incompatible for Chrome OS, consider adding "
        "optional features \"android.hardware.camera\" and "
        "\"android.hardware.camera.autofocus\".",
    correctionMessage:
        "Try adding `<uses-feature android:name=\"android.hardware.camera\"  "
        "android:required=\"false\">` `<uses-feature "
        "android:name=\"android.hardware.camera.autofocus\"  "
        "android:required=\"false\">`.",
    expectedTypes: [],
  );

  /// A code indicating that the activity is set to be non resizable.
  ///
  /// No parameters.
  static const ManifestWarningWithoutArguments
  nonResizableActivity = ManifestWarningWithoutArguments(
    'NON_RESIZABLE_ACTIVITY',
    "The `<activity>` element should be allowed to be resized to allow users "
        "to take advantage of the multi-window environment on Chrome OS",
    correctionMessage:
        "Consider declaring the corresponding activity element with "
        "`resizableActivity=\"true\"` attribute.",
    expectedTypes: [],
  );

  /// A code indicating that the touchscreen feature is not specified in the
  /// manifest.
  ///
  /// No parameters.
  static const ManifestWarningWithoutArguments
  noTouchscreenFeature = ManifestWarningWithoutArguments(
    'NO_TOUCHSCREEN_FEATURE',
    "The default \"android.hardware.touchscreen\" needs to be optional for "
        "Chrome OS.",
    correctionMessage:
        "Consider adding <uses-feature "
        "android:name=\"android.hardware.touchscreen\" android:required=\"false\" "
        "/> to the manifest.",
    expectedTypes: [],
  );

  /// A code indicating that a specified permission is not supported on Chrome
  /// OS.
  ///
  /// Parameters:
  /// Object p0: the name of the feature tag
  static const ManifestWarningTemplate<
    LocatableDiagnostic Function({required Object p0})
  >
  permissionImpliesUnsupportedHardware = ManifestWarningTemplate(
    'PERMISSION_IMPLIES_UNSUPPORTED_HARDWARE',
    "Permission makes app incompatible for Chrome OS, consider adding optional "
        "{0} feature tag,",
    correctionMessage:
        " Try adding `<uses-feature android:name=\"{0}\"  "
        "android:required=\"false\">`.",
    withArguments: _withArgumentsPermissionImpliesUnsupportedHardware,
    expectedTypes: [ExpectedType.object],
  );

  /// A code indicating that the activity is locked to an orientation.
  ///
  /// No parameters.
  static const ManifestWarningWithoutArguments
  settingOrientationOnActivity = ManifestWarningWithoutArguments(
    'SETTING_ORIENTATION_ON_ACTIVITY',
    "The `<activity>` element should not be locked to any orientation so that "
        "users can take advantage of the multi-window environments and larger "
        "screens on Chrome OS",
    correctionMessage:
        "Consider declaring the corresponding activity element with "
        "`screenOrientation=\"unspecified\"` or `\"fullSensor\"` attribute.",
    expectedTypes: [],
  );

  /// A code indicating that a specified feature is not supported on Chrome OS.
  ///
  /// Parameters:
  /// String p0: the name of the feature
  static const ManifestWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unsupportedChromeOsFeature = ManifestWarningTemplate(
    'UNSUPPORTED_CHROME_OS_FEATURE',
    "The feature {0} isn't supported on Chrome OS, consider making it "
        "optional.",
    correctionMessage:
        "Try changing to `android:required=\"false\"` for this feature.",
    withArguments: _withArgumentsUnsupportedChromeOsFeature,
    expectedTypes: [ExpectedType.string],
  );

  /// A code indicating that a specified hardware feature is not supported on
  /// Chrome OS.
  ///
  /// Parameters:
  /// String p0: the name of the feature
  static const ManifestWarningTemplate<
    LocatableDiagnostic Function({required String p0})
  >
  unsupportedChromeOsHardware = ManifestWarningTemplate(
    'UNSUPPORTED_CHROME_OS_HARDWARE',
    "The feature {0} isn't supported on Chrome OS, consider making it "
        "optional.",
    correctionMessage:
        "Try adding `android:required=\"false\"` for this feature.",
    withArguments: _withArgumentsUnsupportedChromeOsHardware,
    expectedTypes: [ExpectedType.string],
  );

  /// Initialize a newly created error code to have the given [name].
  const ManifestWarningCode(
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
         uniqueName: 'ManifestWarningCode.${uniqueName ?? name}',
       );

  @override
  DiagnosticSeverity get severity => DiagnosticSeverity.WARNING;

  @override
  DiagnosticType get type => DiagnosticType.STATIC_WARNING;

  static LocatableDiagnostic
  _withArgumentsPermissionImpliesUnsupportedHardware({required Object p0}) {
    return LocatableDiagnosticImpl(permissionImpliesUnsupportedHardware, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnsupportedChromeOsFeature({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(unsupportedChromeOsFeature, [p0]);
  }

  static LocatableDiagnostic _withArgumentsUnsupportedChromeOsHardware({
    required String p0,
  }) {
    return LocatableDiagnosticImpl(unsupportedChromeOsHardware, [p0]);
  }
}

final class ManifestWarningTemplate<T extends Function>
    extends ManifestWarningCode {
  final T withArguments;

  /// Initialize a newly created error code to have the given [name].
  const ManifestWarningTemplate(
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

final class ManifestWarningWithoutArguments extends ManifestWarningCode
    with DiagnosticWithoutArguments {
  /// Initialize a newly created error code to have the given [name].
  const ManifestWarningWithoutArguments(
    super.name,
    super.problemMessage, {
    super.correctionMessage,
    super.hasPublishedDocs = false,
    super.isUnresolvedIdentifier = false,
    super.uniqueName,
    required super.expectedTypes,
  });
}
