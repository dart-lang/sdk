// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library CssTest;

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
  group('supportsPointConversions', () {
    test('supported', () {
      expect(Window.supportsPointConversions, true);
    });
  });

  group('functional', () {
    test('DomPoint', () {
      var expectation =
          Window.supportsPointConversions ? returnsNormally : throws;
      expect(() {
        Element element = new Element.tag('div');
        element.attributes['style'] = '''
          position: absolute;
          width: 60px;
          height: 100px;
          left: 0px;
          top: 0px;
          background-color: red;
          -webkit-transform: translate3d(250px, 100px, 0px);
          -moz-transform: translate3d(250px, 100px, 0px);
          ''';
        document.body!.append(element);

        var elemRect = element.getBoundingClientRect();

        checkPoint(250, 100, new Point(elemRect.left, elemRect.top));
        checkPoint(310, 200, new Point(elemRect.right, elemRect.bottom));
      }, expectation);
    });
  });
}

void checkPoint(expectedX, expectedY, Point point) {
  expect(point.x.round(), equals(expectedX), reason: 'Wrong point.x');
  expect(point.y.round(), equals(expectedY), reason: 'Wrong point.y');
}
