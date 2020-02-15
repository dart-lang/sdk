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

FileSystem fs;

main() async {
  getFileSystem() async {
    var fileSystem = await window.requestFileSystem(100);
    fs = fileSystem;
  }

  // Do the boilerplate to get several files and directories created to then
  // test the functions that use those items.
  Future doDirSetup(String testName) async {
    await getFileSystem();

    var file = await fs.root.createFile('file_$testName');
    var dir = await fs.root.createDirectory('dir_$testName');
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

