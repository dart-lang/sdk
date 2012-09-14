#library('DOMConstructorsTest');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();
  test('FileReader', () {
    FileReader fileReader = new FileReader();
    Expect.equals(FileReader.EMPTY, fileReader.readyState);
  });
}
