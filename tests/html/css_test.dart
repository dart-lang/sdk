library CssTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

  group('supported_CssMatrix', () {
    test('supported', () {
      expect(CssMatrix.supported, true);
    });
  });

  group('supported_DomPoint', () {
    test('supported', () {
      expect(DomPoint.supported, true);
    });
  });

  group('functional', () {
    test('CssMatrix', () {
      var expectation = CssMatrix.supported ? returnsNormally : throws;
      expect(() {
        CssMatrix matrix1 = new CssMatrix();
        expect(matrix1.m11.round(), equals(1));
        expect(matrix1.m12.round(), isZero);

        CssMatrix matrix2 = new CssMatrix('matrix(1, 0, 0, 1, -835, 0)');
        expect(matrix2.a.round(), equals(1));
        expect(matrix2.e.round(), equals(-835));
      }, expectation);
    });
    test('DomPoint', () {
      var expectation = DomPoint.supported ? returnsNormally : throws;
      expect(() {
        Element element = new Element.tag('div');
        element.attributes['style'] =
          '''
          position: absolute;
          width: 60px;
          height: 100px;
          left: 0px;
          top: 0px;
          background-color: red;
          -webkit-transform: translate3d(250px, 100px, 0px);
          ''';
        document.body.nodes.add(element);

        DomPoint point = new DomPoint(5, 2);
        checkPoint(5, 2, point);
        checkPoint(255, 102, window.convertPointFromNodeToPage(element, point));
        point.y = 100;
        checkPoint(5, 100, point);
        checkPoint(255, 200, window.convertPointFromNodeToPage(element, point));
      }, expectation);
    });
  });
}

void checkPoint(expectedX, expectedY, DomPoint point) {
  expect(point.x.round(), equals(expectedX), reason: 'Wrong point.x');
  expect(point.y.round(), equals(expectedY), reason: 'Wrong point.y');
}
