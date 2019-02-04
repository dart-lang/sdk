// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Detect if we're on Windows without importing `dart:io`.
bool isWindows = new Uri.directory("C:\\").path ==
    new Uri.directory("C:\\", windows: true).path;

Uri resolveInputUri(String path) {
  Uri uri;
  if (path.indexOf(":") == -1) {
    uri = new Uri.file(path, windows: isWindows);
  } else if (!isWindows) {
    uri = parseUri(path);
  } else {
    uri = resolveAmbiguousWindowsPath(path);
  }
  return Uri.base.resolveUri(uri);
}

Uri parseUri(String path) {
  if (path.startsWith("file:")) {
    if (Uri.base.scheme == "file") {
      // The Uri class doesn't handle relative file URIs correctly, the
      // following works around that issue.
      return new Uri(path: Uri.parse("x-$path").path);
    }
  }
  return Uri.parse(path);
}

Uri resolveAmbiguousWindowsPath(String path) {
  try {
    return new Uri.file(path, windows: isWindows);
  } on ArgumentError catch (_) {
    return parseUri(path);
  }
}
