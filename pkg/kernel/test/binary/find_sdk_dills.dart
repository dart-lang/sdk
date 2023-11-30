// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// Finds unique dills in the sdk.
///
/// Note that it reads all dills found to create and compare a checksum to
/// remove duplicates (and re-read on checksum matches).
List<File> findSdkDills() {
  File exe = new File(Platform.resolvedExecutable).absolute;
  int steps = 0;
  Directory parent = exe.parent.parent;
  while (true) {
    Set<String> foundDirs = {};
    for (FileSystemEntity entry in parent.listSync(recursive: false)) {
      if (entry is Directory) {
        List<String> pathSegments = entry.uri.pathSegments;
        String name = pathSegments[pathSegments.length - 2];
        foundDirs.add(name);
      }
    }
    if (foundDirs.contains("pkg") &&
        foundDirs.contains("tools") &&
        foundDirs.contains("tests")) {
      break;
    }
    steps++;
    if (parent.uri == parent.parent.uri) {
      throw "Reached end without finding the root.";
    }
    parent = parent.parent;
  }
  // We had to go $steps steps to reach the "root" --- now we should go 2 steps
  // shorter to be in the "compiled dir".
  parent = exe.parent;
  for (int i = steps - 2; i >= 0; i--) {
    parent = parent.parent;
  }

  List<File> dills = [];
  List<int> checksums = [];
  for (FileSystemEntity entry in parent.listSync(recursive: false)) {
    if (entry is File) {
      if (entry.path.toLowerCase().endsWith(".dill")) {
        _addIfNotDuplicate(entry, dills, checksums);
      }
    }
  }
  Directory sdk = new Directory.fromUri(parent.uri.resolve("dart-sdk/"));
  for (FileSystemEntity entry in sdk.listSync(recursive: true)) {
    if (entry is File) {
      if (entry.path.toLowerCase().endsWith(".dill")) {
        _addIfNotDuplicate(entry, dills, checksums);
      }
    }
  }
  return dills;
}

void _addIfNotDuplicate(File f, List<File> existingFiles, List<int> checksums) {
  List<int> content = f.readAsBytesSync();
  int adler = adler32(content);
  for (int i = 0; i < checksums.length; i++) {
    if (checksums[i] == adler) {
      List<int> existingContent = existingFiles[i].readAsBytesSync();
      bool duplicate = existingContent.length == content.length;
      if (duplicate) {
        for (int j = 0; j < existingContent.length; j++) {
          if (existingContent[j] != content[j]) {
            duplicate = false;
            break;
          }
        }
      }
      if (duplicate) return;
    }
  }
  checksums.add(adler);
  existingFiles.add(f);
}

int adler32(List<int> data) {
  int a = 1;
  int b = 0;
  for (int i = 0; i < data.length; i++) {
    a += data[i];
    b += a;

    if (i & 255 == 255) {
      a %= 65521;
      b %= 65521;
    }
  }
  a %= 65521;
  b %= 65521;
  return (b << 16) | a;
}
