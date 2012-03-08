#library('DOMConstructorsTest');
#import('../../../testing/unittest/unittest_dom.dart');
#import('dart:dom');

main() {
  forLayoutTests();
  test('FileReader', () {
    FileReader fileReader = new FileReader();
    Expect.equals(FileReader.EMPTY, fileReader.readyState);
  });
}
