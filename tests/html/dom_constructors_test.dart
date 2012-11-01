library DOMConstructorsTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();
  test('FileReader', () {
    FileReader fileReader = new FileReader();
    expect(fileReader.readyState, equals(FileReader.EMPTY));
  });
}
