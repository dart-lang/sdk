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

    test('fileDoesntExist', () async {
      try {
        var fileObj = await fs.root!.getFile('file2');
        fail("file found");
      } on DomException catch (error) {
        expect(DomException.NOT_FOUND, error.name);
      }
    });

    test('fileCreate', () async {
      var fileObj = await fs.root!.createFile('file4');
      expect(fileObj.name, equals('file4'));
      expect(fileObj.isFile, isTrue);

      var metadata = await fileObj.getMetadata();
      var changeTime = metadata.modificationTime;

      // Increased Windows buildbots can sometimes be particularly slow.
      expect(new DateTime.now().difference(changeTime).inMinutes < 4, isTrue);
      expect(metadata.size, equals(0));
    });
  }
}
