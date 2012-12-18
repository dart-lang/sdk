library CssTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();
  test('CssMatrix', () {
    CssMatrix matrix1 = new CssMatrix();
    expect(matrix1.m11.round(), equals(1));
    expect(matrix1.m12.round(), isZero);

    CssMatrix matrix2 = new CssMatrix('matrix(1, 0, 0, 1, -835, 0)');
    expect(matrix2.a.round(), equals(1));
    expect(matrix2.e.round(), equals(-835));
  });
}
