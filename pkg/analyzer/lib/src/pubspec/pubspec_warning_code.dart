// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';

/**
 * The error codes used for warnings in analysis options files. The convention
 * for this class is for the name of the error code to indicate the problem that
 * caused the error to be generated and for the error message to explain what is
 * wrong and, when appropriate, how the problem can be corrected.
 */
class PubspecWarningCode extends ErrorCode {
  /**
   * A code indicating that a specified asset does not exist.
   *
   * Parameters:
   * 0: the path to the asset as given in the file.
   */
  static const PubspecWarningCode ASSET_DOES_NOT_EXIST =
      const PubspecWarningCode(
          'ASSET_DOES_NOT_EXIST',
          "The asset {0} does not exist.",
          "Try creating the file or fixing the path to the file.");

  /**
   * A code indicating that the value of the asset field is not a list.
   */
  static const PubspecWarningCode ASSET_FIELD_NOT_LIST = const PubspecWarningCode(
      'ASSET_FIELD_NOT_LIST',
      "The value of the 'asset' field is expected to be a list of relative file paths.",
      "Try converting the value to be a list of relative file paths.");

  /**
   * A code indicating that an element in the asset list is not a string.
   */
  static const PubspecWarningCode ASSET_NOT_STRING = const PubspecWarningCode(
      'ASSET_NOT_STRING',
      "Assets are expected to be a file paths (strings).",
      "Try converting the value to be a string.");

  /**
   * A code indicating that the value of a dependencies field is not a map.
   */
  static const PubspecWarningCode DEPENDENCIES_FIELD_NOT_MAP =
      const PubspecWarningCode(
          'DEPENDENCIES_FIELD_NOT_MAP',
          "The value of the '{0}' field is expected to be a map.",
          "Try converting the value to be a map.");

  /**
   * A code indicating that the value of the flutter field is not a map.
   */
  static const PubspecWarningCode FLUTTER_FIELD_NOT_MAP =
      const PubspecWarningCode(
          'FLUTTER_FIELD_NOT_MAP',
          "The value of the 'flutter' field is expected to be a map.",
          "Try converting the value to be a map.");

  /**
   * A code indicating that the name field is missing.
   */
  static const PubspecWarningCode MISSING_NAME = const PubspecWarningCode(
      'MISSING_NAME',
      "The name field is required but missing.",
      "Try adding a field named 'name'.");

  /**
   * A code indicating that the name field is not a string.
   */
  static const PubspecWarningCode NAME_NOT_STRING = const PubspecWarningCode(
      'NAME_NOT_STRING',
      "The value of the name field is expected to be a string.",
      "Try converting the value to be a string.");

  /**
   * A code indicating that a package listed as a dev dependency is also listed
   * as a normal dependency.
   *
   * Parameters:
   * 0: the name of the package in the dev_dependency list.
   */
  static const PubspecWarningCode UNNECESSARY_DEV_DEPENDENCY =
      const PubspecWarningCode(
          'UNNECESSARY_DEV_DEPENDENCY',
          "The dev dependency on {0} is unnecessary because there is also a "
          "normal dependency on that package.",
          "Try removing the dev dependency.");

  /**
   * Initialize a newly created warning code to have the given [name], [message]
   * and [correction].
   */
  const PubspecWarningCode(String name, String message, [String correction])
      : super(name, message, correction);

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.WARNING;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}
