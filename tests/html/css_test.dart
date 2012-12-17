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
  test('Point', () {
    Element element = new Element.tag('div');
    element.attributes['style'] =
      '''
      position: absolute;
      width: 60px;
      height: 100px;
      left: 0px;
      top: 0px;
      background-color: red;
      -webkit-transform: translate3d(250px, 100px, 0px) perspective(500px) rotateX(30deg);
      ''';
    document.body.nodes.add(element);
  });
}

void checkPoint(expectedX, expectedY, Point point) {
  expect(point.x.round(), equals(expectedX), reason: 'Wrong point.x');
  expect(point.y.round(), equals(expectedY), reason: 'Wrong point.y');
}
