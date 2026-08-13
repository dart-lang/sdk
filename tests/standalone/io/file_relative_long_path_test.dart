// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test is Windows-only. It tests a short (shorter than 260) relative path
// representing a long absolute path cannot be used by Windows API. Running this
// test without proper support on long path will get an error.

import 'dart:io';

const maxPath = 260;

void main(args) {
  if (!Platform.isWindows) {
    return;
  }
  final dir = Directory.systemTemp.createTempSync('test');

  if (dir.path.length >= maxPath) {
    return;
  }

  // Make sure oldpath is shorter than MAX_PATH (260).
  int length = (maxPath - dir.path.length) ~/ 2;
  final oldpath = Directory('${dir.path}\\${'x' * length}}');
  oldpath.createSync(recursive: true);
  final temp = Directory.current;

  Directory.current = oldpath.path;

  // The length of relative path is always shorter than maxPath, but it
  // represents a path exceeding the maxPath.
  final newpath = Directory('.\\${'y' * 2 * length}');
  newpath.createSync();

  // Reset current directory before deletion.
  Directory.current = temp.path;
  dir.deleteSync(recursive: true);
}
