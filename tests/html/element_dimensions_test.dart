// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file

library element_dimensions_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';

main() {
  useHtmlConfiguration();

  var isElement = predicate((x) => x is Element, 'is an Element');
  var isCanvasElement =
      predicate((x) => x is CanvasElement, 'is a CanvasElement');
  var isDivElement = predicate((x) => x is DivElement, 'is a isDivElement');

  var div = new DivElement();
  div.id = 'test';
  document.body.nodes.add(div);

  void initDiv() {
    var style = div.style;
    style
      ..padding = '4px'
      ..border = '0px solid #fff'
      ..margin = '6px'
      ..height = '10px'
      ..width = '11px'
      ..boxSizing = 'content-box'
      ..overflow = 'visible';
  }

  div.nodes.addAll([
    new DivElement(),
    new CanvasElement(),
    new DivElement(),
    new Text('Hello'),
    new DivElement(),
    new Text('World'),
    new CanvasElement()
  ]);

  group('dimensions', () {
    setUp(initDiv);

    test('contentEdge.height', () {
      var all1 = queryAll('#test');

      expect(all1.contentEdge.height, 10);
      expect(all1[0].getComputedStyle().getPropertyValue('height'), '10px');

      all1.contentEdge.height = new Dimension.px(600);
      all1.contentEdge.height = 600;
      expect(all1.contentEdge.height, 600);
      expect(all1[0].getComputedStyle().getPropertyValue('height'), '600px');
      all1[0].style.visibility = 'hidden';
      expect(all1.contentEdge.height, 600);
      all1[0].style.visibility = 'visible';

      // If user passes in a negative number, set height to 0.
      all1.contentEdge.height = new Dimension.px(-1);
      expect(all1.contentEdge.height, 0);

      // Adding padding or border shouldn't affect the height for
      // non-box-sizing.
      div.style.padding = '20pc';
      expect(all1.contentEdge.height, 0);
      div.style.border = '2px solid #fff';
      expect(all1.contentEdge.height, 0);
    });

    test('contentEdge.height with border-box', () {
      var all1 = queryAll('#test');
      div.style.boxSizing = 'border-box';
      expect(all1.contentEdge.height, 2);
      div.style.padding = '20pc';
      expect(all1.contentEdge.height, 0);
      div.style.border = '2px solid #fff';
      expect(all1.contentEdge.height, 0);
    });

    test('contentEdge.width', () {
      var all1 = queryAll('#test');
      expect(all1.contentEdge.width, 11);
      expect(all1[0].getComputedStyle().getPropertyValue('width'), '11px');

      all1.contentEdge.width = new Dimension.px(600);
      expect(all1.contentEdge.width, 600);
      expect(all1[0].getComputedStyle().getPropertyValue('width'), '600px');
      all1[0].style.visibility = 'hidden';
      expect(all1.contentEdge.width, 600);
      all1[0].style.visibility = 'visible';

      // If user passes in a negative number, set width to 0.
      all1.contentEdge.width = new Dimension.px(-1);
      expect(all1.contentEdge.width, 0);

      // Adding padding or border shouldn't affect the width.
      div.style.padding = '20pc';
      expect(all1.contentEdge.width, 0);
      div.style.border = '2px solid #fff';
      expect(all1.contentEdge.width, 0);
    });

    test('contentEdge.width with border-box', () {
      var all1 = queryAll('#test');
      div.style.boxSizing = 'border-box';
      expect(all1.contentEdge.width, 3);
      div.style.padding = '20pc';
      expect(all1.contentEdge.width, 0);
      div.style.border = '2px solid #fff';
      expect(all1.contentEdge.width, 0);
    });

    test('paddingEdge.height', () {
      var all1 = queryAll('#test');
      expect(all1.paddingEdge.height, 18);
      all1[0].style.visibility = 'hidden';
      expect(all1.paddingEdge.height, 18);
      all1[0].style.visibility = 'visible';

      // Adding border shouldn't affect the paddingEdge.height.
      div.style.border = '2px solid #fff';
      expect(all1.paddingEdge.height, 18);
      // Adding padding should affect the paddingEdge.height.
      div.style.padding = '20pc';
      expect(all1.paddingEdge.height, 650);
    });

    test('paddingEdge.height with border-box', () {
      var all1 = queryAll('#test');
      div.style.boxSizing = 'border-box';
      expect(all1.paddingEdge.height, 10);
      div.style.padding = '20pc';
      expect(all1.paddingEdge.height, 640);
      div.style.border = '2px solid #fff';
      expect(all1.paddingEdge.height, 640);
    });

    test('paddingEdge.width', () {
      var all1 = queryAll('#test');
      expect(all1.paddingEdge.width, 19);
      all1[0].style.visibility = 'hidden';
      expect(all1.paddingEdge.width, 19);
      all1[0].style.visibility = 'visible';

      // Adding border shouldn't affect the width.
      div.style.border = '2px solid #fff';
      expect(all1.paddingEdge.width, 19);

      // Adding padding should affect the paddingEdge.width.
      div.style.padding = '20pc';
      expect(all1.paddingEdge.width, 651);
    });

    test('paddingEdge.width with border-box', () {
      var all1 = queryAll('#test');
      div.style.boxSizing = 'border-box';
      expect(all1.paddingEdge.width, 11);
      div.style.padding = '20pc';
      expect(all1.paddingEdge.width, 640);
      div.style.border = '2px solid #fff';
      expect(all1.paddingEdge.width, 640);
    });

    test('borderEdge.height and marginEdge.height', () {
      var all1 = queryAll('#test');
      expect(div.borderEdge.height, 18);
      expect(div.marginEdge.height, 30);
      expect(all1.borderEdge.height, 18);
      expect(all1.marginEdge.height, 30);
      all1[0].style.visibility = 'hidden';
      expect(all1.borderEdge.height, 18);
      all1[0].style.visibility = 'visible';

      // Adding border should affect the borderEdge.height.
      div.style.border = '2px solid #fff';
      expect(all1.borderEdge.height, 22);
      // Adding padding should affect the borderEdge.height.
      div.style.padding = '20pc';
      expect(all1.borderEdge.height, 654);
      expect(all1.marginEdge.height, 666);
    });

    test('borderEdge.height and marginEdge.height with border-box', () {
      var all1 = queryAll('#test');
      div.style.boxSizing = 'border-box';
      expect(all1.borderEdge.height, 10);
      expect(all1.marginEdge.height, 22);
      div.style.padding = '20pc';
      expect(all1.borderEdge.height, 640);
      expect(all1.marginEdge.height, 652);
      div.style.border = '2px solid #fff';
      expect(all1.borderEdge.height, 644);
      expect(all1.marginEdge.height, 656);
    });

    test('borderEdge.width and marginEdge.width', () {
      var all1 = queryAll('#test');
      expect(all1.borderEdge.width, 19);
      expect(all1.marginEdge.width, 31);

      // Adding border should affect the width.
      div.style.border = '2px solid #fff';
      expect(all1.borderEdge.width, 23);

      // Adding padding should affect the borderEdge.width.
      div.style.padding = '20pc';
      expect(all1.borderEdge.width, 655);
      expect(all1.marginEdge.width, 667);
    });

    test('borderEdge.width and marginEdge.width with border-box', () {
      var all1 = queryAll('#test');
      div.style.boxSizing = 'border-box';
      expect(all1.borderEdge.width, 11);
      expect(all1.marginEdge.width, 23);
      div.style.padding = '20pc';
      expect(all1.borderEdge.width, 640);
      expect(all1.marginEdge.width, 652);
      div.style.border = '2px solid #fff';
      expect(all1.borderEdge.width, 644);
      expect(all1.marginEdge.width, 656);
    });

    test('left and top', () {
      div.style.border = '1px solid #fff';
      div.style.margin = '6px 7px';
      div.style.padding = '4px 5px';
      var all1 = queryAll('#test');

      expect(all1.borderEdge.left, all1[0].getBoundingClientRect().left);
      expect(all1.borderEdge.top, all1[0].getBoundingClientRect().top);

      expect(
          all1.contentEdge.left, all1[0].getBoundingClientRect().left + 1 + 5);
      expect(all1.contentEdge.top, all1[0].getBoundingClientRect().top + 1 + 4);

      expect(all1.marginEdge.left, all1[0].getBoundingClientRect().left - 7);
      expect(all1.marginEdge.top, all1[0].getBoundingClientRect().top - 6);

      expect(all1.paddingEdge.left, all1[0].getBoundingClientRect().left + 1);
      expect(all1.paddingEdge.top, all1[0].getBoundingClientRect().top + 1);
    });

    test('setHeight ElementList', () {
      div.style.border = '1px solid #fff';
      div.style.margin = '6px 7px';
      div.style.padding = '4px 5px';
      var all1 = queryAll('div');
      all1.contentEdge.height = new Dimension.px(200);
      all1.contentEdge.height = 200;
      for (Element elem in all1) {
        expect(elem.contentEdge.height, 200);
      }
      all1.contentEdge.height = new Dimension.px(10);
      for (Element elem in all1) {
        expect(elem.contentEdge.height, 10);
      }
    });
  });
}
