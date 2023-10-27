// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9
library fileapi;

import 'dart:async';
import 'dart:html';

import 'package:async_helper/async_minitest.dart';

class FileAndDir {
  FileEntry file;
  DirectoryEntry dir;
  FileAndDir(this.file, this.dir);
}

main() {
  if (!FileSystem.supported) return;
  // Prepend this file name to prevent collisions among tests runnning on the
  // same browser.
  const prefix = 'fileapi_entry_';

  // Do the boilerplate to get several files and directories created to then
  // test the functions that use those items.
  Future doDirSetup(FileSystem fs, String testName) async {
    var file =
        await fs.root.createFile('${prefix}file_$testName') as FileEntry;
    var dir = await fs.root.createDirectory('${prefix}dir_$testName')
        as DirectoryEntry;
    return new Future.value(new FileAndDir(file, dir));
  }

  test('copy_move', () async {
    final fs = await window.requestFileSystem(100);
    var fileAndDir = await doDirSetup(fs, 'copyTo');
    var entry =
        await fileAndDir.file.copyTo(fileAndDir.dir, name: 'copiedFile');
    expect(entry.isFile, true, reason: "Expected File");
    expect(entry.name, 'copiedFile');

    // getParent
    fileAndDir = await doDirSetup(fs, 'getParent');
    entry = await fileAndDir.file.getParent();
    expect(entry.name, '');
    expect(entry.isDirectory, true, reason: "Expected Directory");

    // moveTo
    fileAndDir = await doDirSetup(fs, 'moveTo');
    entry = await fileAndDir.file.moveTo(fileAndDir.dir, name: 'movedFile');
    expect(entry.name, 'movedFile');
    expect(entry.fullPath, '/${prefix}dir_moveTo/movedFile');

    try {
      entry = await fs.root.getFile('${prefix}file4');
      fail("File ${prefix}file4 should not exist.");
    } on DomException catch (error) {
      expect(DomException.NOT_FOUND, error.name);
    }

    // remove
    fileAndDir = await doDirSetup(fs, 'remove');
    expect('${prefix}file_remove', fileAndDir.file.name);
    await fileAndDir.file.remove();
    try {
      await fileAndDir.dir.getFile(fileAndDir.file.name);
      fail("file not removed");
    } on DomException catch (error) {
      expect(DomException.NOT_FOUND, error.name);
    }
  });
}
