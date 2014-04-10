library CssTest;
import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

  group('supportsPointConversions', () {
    test('supported', () {
      expect(Window.supportsPointConversions, true);
    });
  });

  group('functional', () {
    test('DomPoint', () {
      var expectation = Window.supportsPointConversions ?
          returnsNormally : throws;
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
        document.body.append(element);

        Point point = new Point(5, 2);
        checkPoint(5, 2, point);
        checkPoint(255, 102, window.convertPointFromNodeToPage(element, point));
        point = new Point(5, 100);
        checkPoint(5, 100, point);
        checkPoint(255, 200, window.convertPointFromNodeToPage(element, point));
      }, expectation);
    });
  });
}

void checkPoint(expectedX, expectedY, Point point) {
  expect(point.x.round(), equals(expectedX), reason: 'Wrong point.x');
  expect(point.y.round(), equals(expectedY), reason: 'Wrong point.y');
}
