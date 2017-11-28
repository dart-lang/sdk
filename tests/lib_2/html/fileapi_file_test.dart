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

    test('fileDoesntExist', () {
      return fs.root.getFile('file2').catchError((error) {
        expect(error.code, equals(FileError.NOT_FOUND_ERR));
      }, test: (e) => e is FileError);
    });

    test('fileCreate', () {
      return fs.root.createFile('file4').then((Entry e) {
        expect(e.name, equals('file4'));
        expect(e.isFile, isTrue);
        return e.getMetadata();
      }).then((Metadata metadata) {
        var changeTime = metadata.modificationTime;
        // Upped because our Windows buildbots can sometimes be particularly
        // slow.
        expect(
            new DateTime.now().difference(changeTime).inMinutes, lessThan(4));
        expect(metadata.size, equals(0));
      });
    });
  }
}

