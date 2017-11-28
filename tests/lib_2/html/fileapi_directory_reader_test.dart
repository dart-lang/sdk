library fileapi;

import 'dart:html';
import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';

class FileAndDir {
  FileEntry file;
  DirectoryEntry dir;
  FileAndDir(this.file, this.dir);
}

FileSystem fs;

main() {
  useHtmlIndividualConfiguration();

  getFileSystem() {
    return window.requestFileSystem(100).then((FileSystem fileSystem) {
      fs = fileSystem;
    });
  }

  // Do the boilerplate to get several files and directories created to then
  // test the functions that use those items.
  Future doDirSetup(String testName) {
    return fs.root.createFile('file_$testName').then((Entry file) {
      return fs.root
          .createDirectory('dir_$testName')
          .then((Entry dir) {
        return new Future.value(new FileAndDir(file, dir));
      });
    });
  }

  if (FileSystem.supported) {
    test('getFileSystem', getFileSystem);

    test('readEntries', () {
      return doDirSetup('readEntries').then((fileAndDir) {
        var reader = fileAndDir.dir.createReader();
        return reader.readEntries();
      }).then((entries) {
        expect(entries is List, true);
      });
    });
  }
}

