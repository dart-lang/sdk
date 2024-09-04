// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:expect/expect.dart";

/// Regression test for https://github.com/dart-lang/sdk/issues/54386.
void testDriveLetterStat() {
  // These are acceptable cases
  final acceptablePathRootDrives = ["C:", "C: ", "C:\\", "C:/"];
  for (final drivePath in acceptablePathRootDrives) {
    final dir = Directory(drivePath);
    final dirStat = dir.statSync();
    Expect.equals(dirStat.type, FileSystemEntityType.directory);
  }
}

// Check that "C:abc" refers
//   either to a file at current directory if current directory is at "C:" drive,
//   or to a file at "C:\\abc", if current directory is not at "C:" drive.
//
// Do this check by looking at system temp directory entries, converting them
// to no-backslash-after-drive-letter form, confirming that original and
// converted refer to the same thing.
void testDriveLetterNoBackslash() {
  final current = Directory.current.path;
  for (var e in Directory.systemTemp.listSync()) {
    final path = e.path;
    if (path.length < 3) return;
    if (path[1] == ':' && path[2] == "\\") {
      final driveletter = path[0];
      var noBackslash = path.substring(0, 2);
      if (path.substring(0, 3).compareTo(current.substring(0, 3)) == 0) {
        for (int i = 0; i < current.length; i++) {
          if (current[i] == '\\') {
            noBackslash += "..\\";
          }
        }
      }
      noBackslash += path.substring(3);
      Expect.equals("${Directory(noBackslash).statSync()}",
          "${Directory(path).statSync()}");
    }
  }
}

void testDeleteLongPathPrefix() {
  var dir = Directory.systemTemp.createTempSync('dart_file_win');
  var dirPath = "\\\\?\\${dir.path}";
  var subPath = dirPath;
  for (int i = 0; i < 16; i++) {
    subPath += "\\a-long-path-segment";
    dir = new Directory(subPath)..createSync();
  }
  Expect.isTrue(dir.path.length > 256);
  var prefixDir = new Directory(dirPath);
  Expect.isTrue(prefixDir.existsSync());
  prefixDir.deleteSync(recursive: true);
  Expect.isFalse(dir.existsSync());
  Expect.isFalse(prefixDir.existsSync());
}

void main() {
  if (!Platform.isWindows) return;
  testDeleteLongPathPrefix();
  testDriveLetterStat();
  testDriveLetterNoBackslash();
}
