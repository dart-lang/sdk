import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  test('FileReader', () {
    FileReader fileReader = new FileReader();
    expect(fileReader.readyState, equals(FileReader.EMPTY));
  });
}
