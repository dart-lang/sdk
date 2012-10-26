// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(terry): Investigate common library for file I/O shared between frog and tools.

/** Abstraction for file systems and utility functions to manipulate paths. */
#library('file_system');

/**
 * Abstraction around file system access to work in a variety of different
 * environments.
 */
abstract class FileSystem {
  String readAll(String filename);

  void writeString(String outfile, String text);

  bool fileExists(String filename);

  void createDirectory(String path, [bool recursive]);
  void removeDirectory(String path, [bool recursive]);
}

/**
 * Replaces all back slashes (\) with forward slashes (/) in [path] and
 * return the result.
 */
String canonicalizePath(String path) {
  return path.replaceAll('\\', '/');
}

/** Join [path1] to [path2]. */
String joinPaths(String path1, String path2) {
  path1 = canonicalizePath(path1);
  path2 = canonicalizePath(path2);

  var pieces = path1.split('/');
  for (var piece in path2.split('/')) {
    if (piece == '..' && pieces.length > 0 && pieces.last != '.'
      && pieces.last != '..') {
      pieces.removeLast();
    } else if (piece != '') {
      if (pieces.length > 0 && pieces.last == '.') {
        pieces.removeLast();
      }
      pieces.add(piece);
    }
  }
  return Strings.join(pieces, '/');
}

/** Returns the directory name for the [path]. */
String dirname(String path) {
  path = canonicalizePath(path);

  int lastSlash = path.lastIndexOf('/', path.length);
  if (lastSlash == -1) {
    return '.';
  } else {
    return path.substring(0, lastSlash);
  }
}

/** Returns the file name without directory for the [path]. */
String basename(String path) {
  path = canonicalizePath(path);

  int lastSlash = path.lastIndexOf('/', path.length);
  if (lastSlash == -1) {
    return path;
  } else {
    return path.substring(lastSlash + 1);
  }
}
