// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library utils;

import 'dart:io';

import 'package:pathos/path.dart' as path;

/// Converts a `file:` [Uri] to a local path string.
String fileUriToPath(Uri uri) {
  if (uri.scheme != 'file') {
    throw new ArgumentError("Uri $uri must have scheme 'file:'.");
  }
  if (Platform.operatingSystem != 'windows') return uri.path;
  if (uri.path.startsWith("/")) {
    // Drive-letter paths look like "file:///C:/path/to/file". The replaceFirst
    // removes the extra initial slash.
    return uri.path.replaceFirst("/", "").replaceAll("/", "\\");
  } else {
    // Network paths look like "file://hostname/path/to/file".
    return "\\\\${uri.path.replaceAll("/", "\\")}";
  }
}

/// Converts a local path string to a `file:` [Uri].
Uri pathToFileUri(String pathString) {
  pathString = path.absolute(pathString);
  if (Platform.operatingSystem != 'windows') {
    return Uri.parse('file://$pathString');
  } else if (path.rootPrefix(pathString).startsWith('\\\\')) {
    // Network paths become "file://hostname/path/to/file".
    return Uri.parse('file:${pathString.replaceAll("\\", "/")}');
  } else {
    // Drive-letter paths become "file:///C:/path/to/file".
    return Uri.parse('file:///${pathString.replaceAll("\\", "/")}');
  }
}
