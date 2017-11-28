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

    test('createWriter', () {
      return doDirSetup('createWriter').then((fileAndDir) {
        return fileAndDir.file.createWriter();
      }).then((writer) {
        expect(writer.position, 0);
        expect(writer.readyState, FileWriter.INIT);
        expect(writer.length, 0);
      });
    });

    test('file', () {
      return doDirSetup('file').then((fileAndDir) {
        return fileAndDir.file.file().then((fileObj) {
          expect(fileObj.name, fileAndDir.file.name);
          expect(fileObj.relativePath, '');
          expect(
              new DateTime.now()
                  .difference(fileObj.lastModifiedDate)
                  .inSeconds,
              lessThan(60));
        });
      });
    });
  }
}

