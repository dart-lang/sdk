// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';

/**
 * The error codes used for warnings in analysis options files. The convention
 * for this class is for the name of the error code to indicate the problem that
 * caused the error to be generated and for the error message to explain what is
 * wrong and, when appropriate, how the problem can be corrected.
 */
class ManifestWarningCode extends ErrorCode {
  /**
   * A code indicating that a specified hardware feature is not supported on Chrome OS.
   */
  static const ManifestWarningCode UNSUPPORTED_CHROME_OS_HARDWARE =
      const ManifestWarningCode('UNSUPPORTED_CHROME_OS_HARDWARE',
          "This hardware feature is not supported on Chrome OS.",
          correction:
              "Try adding `android:required=\"false\"` for this hardware " +
                  "feature.");

  /**
   * A code indicating that a specified permission is not supported on Chrome OS.
   */
  static const ManifestWarningCode PERMISSION_IMPLIES_UNSUPPORTED_HARDWARE =
      const ManifestWarningCode(
          'PERMISSION_IMPLIES_UNSUPPORTED_HARDWARE',
          "Permission exists without corresponding hardware tag `<uses-feature " +
              "android:name=\"{0}\"  android:required=\"false\">`.",
          correction:
              "Try adding the uses-feature with required=\"false\" attribute value.");

  /**
   * A code indicating that the camera permissions is not supported on Chrome OS.
   */
  static const ManifestWarningCode CAMERA_PERMISSIONS_INCOMPATIBLE =
      const ManifestWarningCode(
          'PERMISSION_IMPLIES_UNSUPPORTED_HARDWARE',
          "Permission exists without corresponding hardware `<uses-feature " +
              "android:name=\"android.hardware.camera\"  android:required=\"false\">` " +
              "`<uses-feature " +
              "android:name=\"android.hardware.camera.autofocus\"  android:required=\"false\">`.",
          correction:
              "Try adding the uses-feature with required=\"false\" attribute value.");

  /**
   * Initialize a newly created warning code to have the given [name], [message]
   * and [correction].
   */
  const ManifestWarningCode(String name, String message, {String correction})
      : super.temporary(name, message, correction: correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.WARNING;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}
