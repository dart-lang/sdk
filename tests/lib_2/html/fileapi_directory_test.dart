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

  if (FileSystem.supported) {
    await getFileSystem();

    test('directoryDoesntExist', () async {
      try {
        await fs.root.getDirectory('directory2');
      } catch (error) {
        expect(true, error is DomException);
        expect(DomException.NOT_FOUND, error.name);
      }
    });

    test('directoryCreate', () async {
      var entry = await fs.root.createDirectory('directory3');
      expect(entry.name, equals('directory3'));
    });
  }

}

