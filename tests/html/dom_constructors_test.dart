#library('DOMConstructorsTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();
  test('FileReader', () {
    FileReader fileReader = new FileReader();
    Expect.equals(FileReader.EMPTY, fileReader.readyState);
  });
}
