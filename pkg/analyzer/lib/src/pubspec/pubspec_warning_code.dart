// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';

/// The error codes used for warnings in analysis options files. The convention
/// for this class is for the name of the error code to indicate the problem
/// that caused the error to be generated and for the error message to explain
/// what is wrong and, when appropriate, how the problem can be corrected.
class PubspecWarningCode extends ErrorCode {
  /// A code indicating that a specified asset does not exist.
  ///
  /// Parameters:
  /// 0: the path to the asset as given in the file.
  static const PubspecWarningCode ASSET_DOES_NOT_EXIST = PubspecWarningCode(
      'ASSET_DOES_NOT_EXIST', "The asset {0} does not exist.",
      correction: "Try creating the file or fixing the path to the file.");

  /// A code indicating that a specified asset directory does not exist.
  ///
  /// Parameters:
  /// 0: the path to the asset directory as given in the file.
  static const PubspecWarningCode ASSET_DIRECTORY_DOES_NOT_EXIST =
      PubspecWarningCode('ASSET_DIRECTORY_DOES_NOT_EXIST',
          "The asset directory {0} does not exist.",
          correction: "Try creating the directory or fixing the path to the "
              "directory.");

  /// A code indicating that the value of the asset field is not a list.
  static const PubspecWarningCode ASSET_FIELD_NOT_LIST = PubspecWarningCode(
      'ASSET_FIELD_NOT_LIST',
      "The value of the 'asset' field is expected to be a list of relative "
          "file paths.",
      correction:
          "Try converting the value to be a list of relative file paths.");

  /// A code indicating that an element in the asset list is not a string.
  static const PubspecWarningCode ASSET_NOT_STRING = PubspecWarningCode(
      'ASSET_NOT_STRING', "Assets are expected to be a file paths (strings).",
      correction: "Try converting the value to be a string.");

  /// A code indicating that the value of a dependencies field is not a map.
  static const PubspecWarningCode DEPENDENCIES_FIELD_NOT_MAP =
      PubspecWarningCode('DEPENDENCIES_FIELD_NOT_MAP',
          "The value of the '{0}' field is expected to be a map.",
          correction: "Try converting the value to be a map.");

  /// A code indicating that the value of the flutter field is not a map.
  static const PubspecWarningCode FLUTTER_FIELD_NOT_MAP = PubspecWarningCode(
      'FLUTTER_FIELD_NOT_MAP',
      "The value of the 'flutter' field is expected to be a map.",
      correction: "Try converting the value to be a map.");

  /// A code indicating that a versioned package has an invalid dependency (git
  /// or path).
  ///
  /// Parameters:
  /// 0: the kind of dependency.
  static const PubspecWarningCode INVALID_DEPENDENCY = PubspecWarningCode(
      'INVALID_DEPENDENCY', "Publishable packages can't have {0} dependencies.",
      correction:
          "Try adding a 'publish_to: none' entry to mark the package as not "
          "for publishing or remove the {0} dependency.");

  /// A code indicating that the name field is missing.
  static const PubspecWarningCode MISSING_NAME = PubspecWarningCode(
      'MISSING_NAME', "The name field is required but missing.",
      correction: "Try adding a field named 'name'.");

  /// A code indicating that the name field is not a string.
  static const PubspecWarningCode NAME_NOT_STRING = PubspecWarningCode(
      'NAME_NOT_STRING',
      "The value of the name field is expected to be a string.",
      correction: "Try converting the value to be a string.");

  /// A code indicating that a specified path dependency does not exist.
  ///
  /// Parameters:
  /// 0: the path to the dependency as given in the file.
  static const PubspecWarningCode PATH_DOES_NOT_EXIST = PubspecWarningCode(
      'PATH_DOES_NOT_EXIST', "The path {0} does not exist.",
      correction:
          "Try creating the referenced path or using a path that exists.");

  /// A code indicating that a path value is not is not posix-style.
  ///
  /// Parameters:
  /// 0: the path as given in the file.
  static const PubspecWarningCode PATH_NOT_POSIX = PubspecWarningCode(
      'PATH_NOT_POSIX', "The path {0} is not posix.",
      correction: "Try converting the value to a posix-style path.");

  /// A code indicating that a specified path dependency points to a directory
  /// that does not contain a pubspec.
  ///
  /// Parameters:
  /// 0: the path to the dependency as given in the file.
  static const PubspecWarningCode PATH_PUBSPEC_DOES_NOT_EXIST = PubspecWarningCode(
      'PATH_PUBSPEC_DOES_NOT_EXIST',
      "The directory {0} does not contain a pubspec.",
      correction:
          "Try creating a pubspec in the referenced directory or using a path that has a pubspec.");

  /// A code indicating that a package listed as a dev dependency is also listed
  /// as a normal dependency.
  ///
  /// Parameters:
  /// 0: the name of the package in the dev_dependency list.
  static const PubspecWarningCode UNNECESSARY_DEV_DEPENDENCY =
      PubspecWarningCode(
          'UNNECESSARY_DEV_DEPENDENCY',
          "The dev dependency on {0} is unnecessary because there is also a "
              "normal dependency on that package.",
          correction: "Try removing the dev dependency.");

  /// Initialize a newly created warning code to have the given [name],
  /// [message] and [correction].
  const PubspecWarningCode(String name, String message, {String correction})
      : super(
          correction: correction,
          message: message,
          name: name,
          uniqueName: 'PubspecWarningCode.$name',
        );

  @override
  ErrorSeverity get errorSeverity => ErrorSeverity.WARNING;

  @override
  ErrorType get type => ErrorType.STATIC_WARNING;
}
