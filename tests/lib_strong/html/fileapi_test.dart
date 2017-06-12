library fileapi;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';
import 'dart:async';

class FileAndDir {
  FileEntry file;
  DirectoryEntry dir;
  FileAndDir(this.file, this.dir);
}

FileSystem fs;

main() {
  useHtmlIndividualConfiguration();

  group('supported', () {
    test('supported', () {
      expect(FileSystem.supported, true);
    });
  });

  getFileSystem() {
    return window.requestFileSystem(100).then((FileSystem fileSystem) {
      fs = fileSystem;
    });
  }

  group('unsupported_throws', () {
    test('requestFileSystem', () {
      var expectation = FileSystem.supported ? returnsNormally : throws;
      expect(() {
        window.requestFileSystem(100);
      }, expectation);
    });
  });

  group('getDirectory', () {
    if (FileSystem.supported) {
      test('getFileSystem', getFileSystem);

      test('directoryDoesntExist', () {
        return fs.root.getDirectory('directory2').catchError((error) {
          expect(error.code, equals(FileError.NOT_FOUND_ERR));
        }, test: (e) => e is FileError);
      });

      test('directoryCreate', () {
        return fs.root.createDirectory('directory3').then((DirectoryEntry e) {
          expect(e.name, equals('directory3'));
        });
      });
    }
  });

  group('getFile', () {
    if (FileSystem.supported) {
      test('getFileSystem', getFileSystem);

      test('fileDoesntExist', () {
        return fs.root.getFile('file2').catchError((error) {
          expect(error.code, equals(FileError.NOT_FOUND_ERR));
        }, test: (e) => e is FileError);
      });

      test('fileCreate', () {
        return fs.root.createFile('file4').then((FileEntry e) {
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
  });

  // Do the boilerplate to get several files and directories created to then
  // test the functions that use those items.
  Future doDirSetup(String testName) {
    return fs.root.createFile('file_$testName').then((FileEntry file) {
      return fs.root
          .createDirectory('dir_$testName')
          .then((DirectoryEntry dir) {
        return new Future.value(new FileAndDir(file, dir));
      });
    });
  }

  group('directoryReader', () {
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
  });

  group('entry', () {
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
  });

  group('fileEntry', () {
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
  });
}
