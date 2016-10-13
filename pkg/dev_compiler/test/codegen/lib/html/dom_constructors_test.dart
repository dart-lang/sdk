import 'dart:html';

import 'package:minitest/minitest.dart';

main() {
  test('FileReader', () {
    FileReader fileReader = new FileReader();
    expect(fileReader.readyState, equals(FileReader.EMPTY));
  });
}
