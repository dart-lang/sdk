#library('fileapi');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();
  window.webkitRequestFileSystem(Window.TEMPORARY, 100, (fs) {
    // FIXME: add types to callback arguments after migration to wrapperless dart:html.
    asyncTest('getDirectory', 2, () {
      Expect.throws(() => fs.root.getDirectory('directory1', {'x': true}, (e) {}));

      fs.root.getDirectory(
          'directory2',
          flags: {},
          successCallback: (e) {
            Expect.fail('Should not be reached');
            callbackDone();
          },
          errorCallback: (e) {
            Expect.equals(FileError.NOT_FOUND_ERR, e.code);
            callbackDone();
          });

      fs.root.getDirectory(
          'directory3',
          flags: {'create': true},
          successCallback: (e) {
            Expect.equals('directory3', e.name);
            callbackDone();
          },
          errorCallback: (e) {
            Expect.fail('Got file error: ${e.code}');
            callbackDone();
          });
    });

    asyncTest('getFile', 2, () {
      Expect.throws(() => fs.root.getFile('file1', {'x': true}, (e) {}));

      fs.root.getDirectory(
          'file2',
          flags: {},
          successCallback: (e) {
            Expect.fail('Should not be reached');
            callbackDone();
          },
          errorCallback: (e) {
            Expect.equals(FileError.NOT_FOUND_ERR, e.code);
            callbackDone();
          });

      fs.root.getDirectory(
          'file3',
          flags: {'create': true},
          successCallback: (e) {
            Expect.equals('file3', e.name);
            callbackDone();
          },
          errorCallback: (e) {
            Expect.fail('Got file error: ${e.code}');
            callbackDone();
          });
    });
  });
}
