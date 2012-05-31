#library('fileapi');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();
  window.webkitRequestFileSystem(Window.TEMPORARY, 100, (fs) {
    // FIXME: add types to callback arguments after migration to wrapperless dart:html.
    test('getDirectory', () {
      Expect.throws(() => fs.root.getDirectory('directory1', {'x': true}, (e) {}));

      fs.root.getDirectory(
          'directory2',
          flags: {},
          successCallback:
            (e) => guardAsync(() => Expect.fail('Should not be reached')),
          errorCallback:
            expectAsync1((e) => Expect.equals(FileError.NOT_FOUND_ERR, e.code))
          );

      fs.root.getDirectory(
          'directory3',
          flags: {'create': true},
          successCallback:
            expectAsync1((e) => Expect.equals('directory3', e.name)),
          errorCallback:
            (e) => guardAsync(() => Expect.fail('Got file error: ${e.code}'))
          );
    });

    test('getFile', () {
      Expect.throws(() => fs.root.getFile('file1', {'x': true}, (e) {}));

      fs.root.getDirectory(
          'file2',
          flags: {},
          successCallback:
            (e) => guardAsync(() => Expect.fail('Should not be reached')),
          errorCallback:
            expectAsync1((e) => Expect.equals(FileError.NOT_FOUND_ERR, e.code))
          );

      fs.root.getDirectory(
          'file3',
          flags: {'create': true},
          successCallback:
            expectAsync1((e) => Expect.equals('file3', e.name)),
          errorCallback:
            (e) => guardAsync(() => Expect.fail('Got file error: ${e.code}'))
          );
    });
  });
}
