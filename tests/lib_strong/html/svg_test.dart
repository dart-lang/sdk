// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:svg' as svg;

import 'package:expect/minitest.dart';

main() {
  group('svgPresence', () {
    var isSvgElement = predicate((x) => x is svg.SvgElement, 'is a SvgElement');

    test('simpleRect', () {
      var div = new Element.tag('div');
      document.body.append(div);
      div.setInnerHtml(
          r'''
<svg id='svg1' width='200' height='100'>
<rect id='rect1' x='10' y='20' width='130' height='40' rx='5'fill='blue'></rect>
</svg>
''',
          validator: new NodeValidatorBuilder()..allowSvg());

      var e = document.query('#svg1');
      expect(e, isNotNull);

      svg.RectElement r = document.query('#rect1');
      expect(r.x.baseVal.value, 10);
      expect(r.y.baseVal.value, 20);
      expect(r.height.baseVal.value, 40);
      expect(r.width.baseVal.value, 130);
      expect(r.rx.baseVal.value, 5);
    });

    test('trailing newline', () {
      // Ensures that we handle SVG with trailing newlines.
      var logo = new svg.SvgElement.svg("""
        <svg xmlns='http://www.w3.org/2000/svg' version='1.1'>
          <path/>
        </svg>
        """);

      expect(logo, isSvgElement);
    });
  });

  group('svgInterfaceMatch', () {
    // Test that SVG elements explicitly implement the IDL interfaces (is-checks
    // only, see SVGTest3 for behavioural tests).
    insertTestDiv() {
      var element = new Element.tag('div');
      element.setInnerHtml(
          r'''
<svg id='svg1' width='200' height='100'>
<rect id='rect1' x='10' y='20' width='130' height='40' rx='5'fill='blue'></rect>
</svg>
''',
          validator: new NodeValidatorBuilder()..allowSvg());
      document.body.append(element);
      return element;
    }

    var isElement = predicate((x) => x is Element, 'is an Element');
    var isSvgElement = predicate((x) => x is svg.SvgElement, 'is a SvgElement');
    var isSvgSvgElement =
        predicate((x) => x is svg.SvgSvgElement, 'is a SvgSvgElement');
    var isNotSvgSvgElement =
        predicate((x) => x is! svg.SvgSvgElement, 'is not a SvgSvgElement');
    var isNode = predicate((x) => x is Node, 'is a Node');
    var isSvgNumber = predicate((x) => x is svg.Number, 'is a svg.Number');
    var isNotSvgNumber =
        predicate((x) => x is! svg.Number, 'is not a svg.Number');
    var isSvgRect = predicate((x) => x is svg.Rect, 'is a svg.Rect');
    var isNotSvgRect = predicate((x) => x is! svg.Rect, 'is not a svg.Rect');

    test('rect_isChecks', () {
      var div = insertTestDiv();
      var r = document.query('#rect1');

      // Direct inheritance chain
      expect(r, isSvgElement);
      expect(r, isElement);
      expect(r, isNode);

      // Interfaces not implemented.
      expect(r, isNotSvgNumber);
      expect(r, isNotSvgRect);
      expect(r, isNotSvgSvgElement);

      div.remove();
    });
  });

  insertTestDiv() {
    var element = new Element.tag('div');
    element.innerHtml = r'''
<svg id='svg1' width='200' height='100'>
<rect id='rect1' x='10' y='20' width='130' height='40' rx='5'fill='blue'></rect>
</svg>
''';
    document.body.append(element);
    return element;
  }

  group('svgBehavioral', () {
    // Test that SVG elements have the operations advertised through all the IDL
    // interfaces.  This is a 'duck typing' test, and does not explicitly use
    // 'is' checks on the expected interfaces (that is in the test group above).

    var isString = predicate((x) => x is String, 'is a String');
    var isStringList = predicate((x) => x is List<String>, 'is a List<String>');
    var isSvgMatrix = predicate((x) => x is svg.Matrix, 'is a svg.Matrix');
    var isSvgAnimatedBoolean =
        predicate((x) => x is svg.AnimatedBoolean, 'is an svg.AnimatedBoolean');
    var isSvgAnimatedString =
        predicate((x) => x is svg.AnimatedString, 'is an svg.AnimatedString');
    var isSvgRect = predicate((x) => x is svg.Rect, 'is a svg.Rect');
    var isSvgAnimatedTransformList = predicate(
        (x) => x is svg.AnimatedTransformList,
        'is an svg.AnimatedTransformList');
    var isCssStyleDeclaration =
        predicate((x) => x is CssStyleDeclaration, 'is a CssStyleDeclaration');

    testRect(name, checker) {
      test(name, () {
        var div = insertTestDiv();
        var r = document.query('#rect1');
        checker(r);
        div.remove();
      });
    }
  });
}
