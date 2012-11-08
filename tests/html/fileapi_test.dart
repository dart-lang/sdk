library fileapi;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

void fail(message) {
  guardAsync(() {
    expect(false, isTrue, reason: message);
  });
}

DOMFileSystem fs;

main() {
  useHtmlConfiguration();
  test('getFileSystem', () {
    window.webkitRequestFileSystem(LocalWindow.TEMPORARY, 100, expectAsync1(
      (DOMFileSystem fileSystem) {
        fs = fileSystem;
      }),
      (e) {
        fail('Got file error: ${e.code}');
      });
  });
  group('getDirectory', () {

    test('directoryDoesntExist', () {
      fs.root.getDirectory(
          'directory2',
          options: {},
          successCallback: (e) {
            fail('Should not be reached');
          },
          errorCallback: expectAsync1((FileError e) {
            expect(e.code, equals(FileError.NOT_FOUND_ERR));
          }));
    });

    test('directoryCreate', () {
      fs.root.getDirectory(
          'directory3',
          options: {'create': true},
          successCallback: expectAsync1((DirectoryEntry e) {
            expect(e.name, equals('directory3'));
          }),
          errorCallback: (e) {
            fail('Got file error: ${e.code}');
          });
    });
  });

  group('getFile', () {

    test('fileDoesntExist', () {
      fs.root.getFile(
          'file2',
          options: {},
          successCallback: (e) {
            fail('Should not be reached');
          },
          errorCallback: expectAsync1((FileError e) {
            expect(e.code, equals(FileError.NOT_FOUND_ERR));
          }));
    });

    test('fileCreate', () {
      fs.root.getFile(
          'file4',
          options: {'create': true},
          successCallback: expectAsync1((FileEntry e) {
            expect(e.name, equals('file4'));
            expect(e.isFile, isTrue);
          }),
          errorCallback: (e) {
            fail('Got file error: ${e.code}');
          });
      });
  });
}
