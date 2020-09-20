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

  if (FileSystem.supported) {
    await getFileSystem();

    test('directoryDoesntExist', () async {
      try {
        await fs.root!.getDirectory('directory2');
      } on DomException catch (error) {
        expect(DomException.NOT_FOUND, error.name);
      }
    });

    test('directoryCreate', () async {
      var entry = await fs.root!.createDirectory('directory3');
      expect(entry.name, equals('directory3'));
    });
  }
}
