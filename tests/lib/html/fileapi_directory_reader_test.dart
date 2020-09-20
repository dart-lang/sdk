// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fileapi;

import 'dart:async';
import 'dart:html';

import 'package:async_helper/async_helper.dart';
import 'package:async_helper/async_minitest.dart';

class FileAndDir {
  FileEntry file;
  DirectoryEntry dir;
  FileAndDir(this.file, this.dir);
}

late FileSystem fs;

main() async {
  getFileSystem() async {
    fs = await window.requestFileSystem(100);
  }

  // Do the boilerplate to get several files and directories created to then
  // test the functions that use those items.
  Future doDirSetup(String testName) async {
    await getFileSystem();

    var file = await fs.root!.createFile('file_$testName') as FileEntry;
    var dir = await fs.root!.createDirectory('dir_$testName') as DirectoryEntry;
    return new Future.value(new FileAndDir(file, dir));
  }

  if (FileSystem.supported) {
    test('readEntries', () async {
      var fileAndDir = await doDirSetup('readEntries');
      var reader = await fileAndDir.dir.createReader();
      var entries = await reader.readEntries();
      expect(entries is List, true);
    });
  }
}
