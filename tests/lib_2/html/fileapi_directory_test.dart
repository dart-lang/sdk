library fileapi;

import 'dart:async';
import 'dart:html';

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

  if (FileSystem.supported) {
    test('getFileSystem', getFileSystem);

    test('directoryDoesntExist', () {
      return fs.root.getDirectory('directory2').catchError((error) {
        expect(error.code, equals(FileError.NOT_FOUND_ERR));
      }, test: (e) => e is FileError);
    });

    test('directoryCreate', () {
      return fs.root.createDirectory('directory3').then((Entry e) {
        expect(e.name, equals('directory3'));
      });
    });
  }
}

