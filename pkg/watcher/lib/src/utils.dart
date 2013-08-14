// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library watcher.utils;

import 'dart:io';

/// Returns `true` if [error] is a [DirectoryException] for a missing directory.
bool isDirectoryNotFoundException(error) {
  if (error is! DirectoryException) return false;

  // See dartbug.com/12461 and tests/standalone/io/directory_error_test.dart.
  var notFoundCode = Platform.operatingSystem == "windows" ? 3 : 2;
  return error.osError.errorCode == notFoundCode;
}
