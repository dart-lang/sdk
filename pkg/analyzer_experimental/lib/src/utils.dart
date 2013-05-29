// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library utils;

import 'dart:io';

import 'package:pathos/path.dart' as pathos;

/// Converts a local path string to a `file:` [Uri].
Uri pathToFileUri(String pathString) {
  pathString = pathos.absolute(pathString);
  if (Platform.operatingSystem != 'windows') {
    return Uri.parse('file://$pathString');
  } else if (pathos.rootPrefix(pathString).startsWith('\\\\')) {
    // Network paths become "file://hostname/path/to/file".
    return Uri.parse('file:${pathString.replaceAll("\\", "/")}');
  } else {
    // Drive-letter paths become "file:///C:/path/to/file".
    return Uri.parse('file:///${pathString.replaceAll("\\", "/")}');
  }
}
