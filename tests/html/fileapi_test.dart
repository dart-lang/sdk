#library('fileapi');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

void fail(message) {
  guardAsync(() {
    Expect.fail(message);
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
      /* OPTIONALS
      fs.root.getDirectory(
          'directory2',
          options: {},
          successCallback: (e) {
            fail('Should not be reached');
          },
          errorCallback: expectAsync1((FileError e) {
            expect(e.code, equals(FileError.NOT_FOUND_ERR));
          }));
      */
      fs.root.getDirectory(
          'directory2',
          {},
          (e) {
            fail('Should not be reached');
          },
          expectAsync1((FileError e) {
            expect(e.code, equals(FileError.NOT_FOUND_ERR));
          }));
    });

    test('directoryCreate', () {
      /* OPTIONALS
      fs.root.getDirectory(
          'directory3',
          options: {'create': true},
          successCallback: expectAsync1((DirectoryEntry e) {
            expect(e.name, equals('directory3'));
          }),
          errorCallback: (e) {
            fail('Got file error: ${e.code}');
          });
      */
      fs.root.getDirectory(
          'directory3',
          {'create': true},
          expectAsync1((DirectoryEntry e) {
            expect(e.name, equals('directory3'));
          }),
          (e) {
            fail('Got file error: ${e.code}');
          });
    });
  });

  group('getFile', () {

    test('fileDoesntExist', () {
      /* OPTIONALS
      fs.root.getFile(
          'file2',
          options: {},
          successCallback: (e) {
            fail('Should not be reached');
          },
          errorCallback: expectAsync1((FileError e) {
            expect(e.code, equals(FileError.NOT_FOUND_ERR));
          }));
      */
      fs.root.getFile(
          'file2',
          {},
          (e) {
            fail('Should not be reached');
          },
          expectAsync1((FileError e) {
            expect(e.code, equals(FileError.NOT_FOUND_ERR));
          }));
    });

    test('fileCreate', () {
      /* OPTIONALS
      fs.root.getFile(
          'file4',
          options: {'create': true},
          successCallback: expectAsync1((FileEntry e) {
            expect(e.name, equals('file4'));
            expect(e.isFile, equals(true));
          }),
          errorCallback: (e) {
            fail('Got file error: ${e.code}');
          });
      });
      */
      fs.root.getFile(
          'file4',
          {'create': true},
          expectAsync1((FileEntry e) {
            expect(e.name, equals('file4'));
            expect(e.isFile, equals(true));
          }),
          (e) {
            fail('Got file error: ${e.code}');
          });
      });
  });
}
