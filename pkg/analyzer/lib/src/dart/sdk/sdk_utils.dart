// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show min;

import 'package:analyzer/src/generated/sdk.dart';

const int _backwardsSlash = 92;
const int _forwardSlash = 47;

String? getImportUriIfMatchesRelativeSdkPath(
    List<SdkLibrary> libraries, String relativePathFromFile, String separator) {
  for (SdkLibrary library in libraries) {
    if (_equalModuloPathSeparator(library.path, relativePathFromFile)) {
      return library.shortName;
    }
  }

  for (SdkLibrary library in libraries) {
    String? relativePathIfInside = getRelativePathIfInside(
        library.path, relativePathFromFile,
        ignoreOsSeparatorMismatch: true);
    if (relativePathIfInside != null) {
      String relPath = relativePathIfInside.replaceAll(separator, '/');
      return '${library.shortName}/$relPath';
    }
  }
  return null;
}

String? getRelativePathIfInside(String libraryPath, String filePath,
    {bool ignoreOsSeparatorMismatch = false}) {
  int minLength = min(libraryPath.length, filePath.length);

  // Find how far the strings are the same (modulo path separators is asked).
  int same = 0;
  for (int i = 0; i < minLength; i++) {
    if (libraryPath.codeUnitAt(i) == filePath.codeUnitAt(i)) {
      same++;
    } else if (ignoreOsSeparatorMismatch &&
        (libraryPath.codeUnitAt(i) == _forwardSlash ||
            libraryPath.codeUnitAt(i) == _backwardsSlash) &&
        (filePath.codeUnitAt(i) == _forwardSlash ||
            filePath.codeUnitAt(i) == _backwardsSlash)) {
      same++;
    } else {
      break;
    }
  }
  // They're the same up to and including index [same].
  // If there isn't a path separator left in the rest of the string [libPath],
  // [filePath] is inside the same dir as [libPath] (possibly within
  // subdirs).
  for (int i = same; i < libraryPath.length; i++) {
    int c = libraryPath.codeUnitAt(i);
    if (c == _forwardSlash || c == _backwardsSlash) {
      return null;
    }
  }

  // To get the relative path we need to go back to the previous path
  // separator.
  for (int i = same; i >= 0; i--) {
    int c = libraryPath.codeUnitAt(i);
    if (c == _forwardSlash || c == _backwardsSlash) {
      return filePath.substring(i + 1);
    }
  }

  // Invalid non-absolute path.
  return null;
}

bool _equalModuloPathSeparator(String path, String relativePathFromFile) {
  if (path.length != relativePathFromFile.length) {
    return false;
  }
  for (int i = 0; i < path.length; i++) {
    if (path.codeUnitAt(i) == relativePathFromFile.codeUnitAt(i)) {
      continue;
    }
    if ((path.codeUnitAt(i) == _forwardSlash ||
            path.codeUnitAt(i) == _backwardsSlash) &&
        (relativePathFromFile.codeUnitAt(i) == _forwardSlash ||
            relativePathFromFile.codeUnitAt(i) == _backwardsSlash)) {
      continue;
    }
    return false;
  }
  return true;
}
