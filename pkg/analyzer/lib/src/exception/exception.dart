// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/exception/exception.dart';

/// Exception that wraps another exception, and includes the content of
/// files that might be related to the exception, and help to identify the
/// issue and fix it.
class CaughtExceptionWithFiles extends CaughtException {
  final Map<String, String> fileContentMap;

  CaughtExceptionWithFiles(
    super.exception,
    super.stackTrace,
    this.fileContentMap,
  );
}

/// Exception thrown when a required SDK class is missing from an SDK library.
final class MissingRequiredSdkClassException implements Exception {
  final Uri libraryUri;
  final String libraryPath;
  final String className;
  final List<String> declaredClassNames;

  MissingRequiredSdkClassException({
    required this.libraryUri,
    required this.libraryPath,
    required this.className,
    required this.declaredClassNames,
  });

  @override
  String toString() {
    var location = '$libraryUri';
    if (libraryPath.isNotEmpty) {
      location += ' ($libraryPath)';
    }

    const maxClassCount = 10;
    var classNamesStr = declaredClassNames.take(maxClassCount).join(', ');

    var message = 'No definition of type $className in $location.';
    if (declaredClassNames.length <= maxClassCount) {
      message += ' Found ${declaredClassNames.length} classes: $classNamesStr';
    } else {
      message +=
          ' Found ${declaredClassNames.length} classes: $classNamesStr, ...';
    }
    return message;
  }
}
