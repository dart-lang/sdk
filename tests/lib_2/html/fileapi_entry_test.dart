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

    test('copyTo', () {
      return doDirSetup('copyTo').then((fileAndDir) {
        return fileAndDir.file.copyTo(fileAndDir.dir, name: 'copiedFile');
      }).then((entry) {
        expect(entry.isFile, true);
        expect(entry.name, 'copiedFile');
      });
    });

    test('getParent', () {
      return doDirSetup('getParent').then((fileAndDir) {
        return fileAndDir.file.getParent();
      }).then((entry) {
        expect(entry.name, '');
        expect(entry.isFile, false);
      });
    });

    test('moveTo', () {
      return doDirSetup('moveTo').then((fileAndDir) {
        return fileAndDir.file.moveTo(fileAndDir.dir, name: 'movedFile');
      }).then((entry) {
        expect(entry.name, 'movedFile');
        expect(entry.fullPath, '/dir_moveTo/movedFile');
        return fs.root.getFile('file4');
      }).catchError((error) {
        expect(error.code, equals(FileError.NOT_FOUND_ERR));
      }, test: (e) => e is FileError);
    });

    test('remove', () {
      return doDirSetup('remove').then((fileAndDir) {
        return fileAndDir.file.remove().then((_) {});
      });
    });
  }
}

