#library('DOMConstructorsTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom_deprecated');

main() {
  useDomConfiguration();
  test('FileReader', () {
    FileReader fileReader = new FileReader();
    Expect.equals(FileReader.EMPTY, fileReader.readyState);
  });
}
