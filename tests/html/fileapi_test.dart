#library('fileapi');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();
  window.webkitRequestFileSystem(Window.TEMPORARY, 100, (fs) {
    // FIXME: add types to callback arguments after migration to wrapperless dart:html.

    test('getDirectory', () {
      expect(() => fs.root.getDirectory('directory1', {'x': true}, (e) {}),
             throws);

      fs.root.getDirectory(
          'directory2',
          flags: {},
          successCallback: expectAsync1((e) {
            expect(false, 'Should not be reached');
          }, count:0),
          errorCallback: expectAsync1((e) {
            expect(e.code, equals(FileError.NOT_FOUND_ERR));
          }));

      fs.root.getDirectory(
          'directory3',
          flags: {'create': true},
          successCallback: expectAsync1((e) {
            expect(e.name, equals('directory3'));
          }),
          errorCallback: expectAsync1((e) {
            expect(false, 'Got file error: ${e.code}');
          }, count:0));
    });

    test('getFile', () {
      expect(() => fs.root.getFile('file1', {'x': true}, (e) {}), throws);

      fs.root.getDirectory(
          'file2',
          flags: {},
          successCallback: expectAsync1((e) {
            expect(false, 'Should not be reached');
          }, count:0),
          errorCallback: expectAsync1((e) {
            expect(e.code, equals(FileError.NOT_FOUND_ERR));
          }));

      fs.root.getDirectory(
          'file3',
          flags: {'create': true},
          successCallback: expectAsync1((e) {
            expect(e.name, equals('file3'));
          }),
          errorCallback: expectAsync1((e) {
            expect(false, 'Got file error: ${e.code}');
          }, count:0));
    });
  });
}
