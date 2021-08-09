// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;

void testList() {
  final startingDir =
      Directory(path.normalize(path.join(Platform.executable, '../../../')));
  print("Recursively listing entries in directory ${startingDir.path} ...");
  List<FileSystemEntity> each =
      startingDir.listSync(recursive: true, followLinks: false);
  print("Found: ${each.length} entities");
}

// The test is disabled by default, because it requires permission to run.
// e.g. sudo dart directory_list_sync_test.dart
void testAnonymousNodeOnLinux() {
  // If a symbolic link points to an anon_inode, which doesn't have a regular
  // file type like an epoll file descriptor, list() will return a link.
  if (!Platform.isLinux) {
    return;
  }
  Directory('/proc/').listSync(recursive: true);
}

void main() {
  testList();
  //testAnonymousNodeOnLinux();
}
