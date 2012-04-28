#library('CSSTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom');

main() {
  useDomConfiguration();
  test('WebKitCSSMatrix', () {
    WebKitCSSMatrix matrix1 = new WebKitCSSMatrix();
    Expect.equals(1, matrix1.m11.round());
    Expect.equals(0, matrix1.m12.round());

    WebKitCSSMatrix matrix2 = new WebKitCSSMatrix('matrix(1, 0, 0, 1, -835, 0)');
    Expect.equals(1, matrix2.a.round());
    Expect.equals(-835, matrix2.e.round());
  });
  test('WebKitPoint', () {
    HTMLElement element = document.createElement('div');
    element.setAttribute('style',
      '''
      position: absolute;
      width: 60px;
      height: 100px;
      left: 0px;
      top: 0px;
      background-color: red;
      -webkit-transform: translate3d(250px, 100px, 0px) perspective(500px) rotateX(30deg);
      ''');
    document.body.appendChild(element);

    WebKitPoint point = new WebKitPoint(5, 2);
    checkPoint(5, 2, point);
    checkPoint(256, 110, window.webkitConvertPointFromNodeToPage(element, point));
    point.y = 100;
    checkPoint(5, 100, point);
    checkPoint(254, 196, window.webkitConvertPointFromNodeToPage(element, point));
  });
}

void checkPoint(expectedX, expectedY, WebKitPoint point) {
  Expect.equals(expectedX, point.x.round(), 'Wrong point.x');
  Expect.equals(expectedY, point.y.round(), 'Wrong point.y');
}
