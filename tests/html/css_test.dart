#library('CSSTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();
  test('CSSMatrix', () {
    CSSMatrix matrix1 = new CSSMatrix();
    expect(matrix1.m11.round(), equals(1));
    expect(matrix1.m12.round(), isZero);

    CSSMatrix matrix2 = new CSSMatrix('matrix(1, 0, 0, 1, -835, 0)');
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

    Point point = new Point(5, 2);
    checkPoint(5, 2, point);
    checkPoint(256, 110, window.webkitConvertPointFromNodeToPage(element, point));
    point.y = 100;
    checkPoint(5, 100, point);
    checkPoint(254, 196, window.webkitConvertPointFromNodeToPage(element, point));
  });
}

void checkPoint(expectedX, expectedY, Point point) {
  expect(point.x.round(), equals(expectedX), 'Wrong point.x');
  expect(point.y.round(), equals(expectedY), 'Wrong point.y');
}
