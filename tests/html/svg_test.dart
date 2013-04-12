// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library SVGTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';
import 'dart:svg' as svg;

main() {
  useHtmlIndividualConfiguration();

  group('svgPresence', () {
    var isSvgElement = predicate((x) => x is svg.SvgElement, 'is a SvgElement');

    test('simpleRect', () {
      var div = new Element.tag('div');
      document.body.nodes.add(div);
      div.innerHtml = r'''
<svg id='svg1' width='200' height='100'>
<rect id='rect1' x='10' y='20' width='130' height='40' rx='5'fill='blue'></rect>
</svg>

''';

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
      element.innerHtml = r'''
<svg id='svg1' width='200' height='100'>
<rect id='rect1' x='10' y='20' width='130' height='40' rx='5'fill='blue'></rect>
</svg>
''';
      document.body.nodes.add(element);
      return element;
    }


    var isElement = predicate((x) => x is Element, 'is an Element');
    var isSvgElement = predicate((x) => x is svg.SvgElement, 'is a SvgElement');
    var isSvgSvgElement =
        predicate((x) => x is svg.SvgSvgElement, 'is a SvgSvgElement');
    var isNode = predicate((x) => x is Node, 'is a Node');
    var isSvgTests = predicate((x) => x is svg.Tests, 'is a svg.Tests');
    var isSvgLangSpace = predicate((x) => x is svg.LangSpace, 'is a svg.LangSpace');
    var isSvgExternalResourcesRequired =
        predicate((x) => x is svg.ExternalResourcesRequired,
            'is a svg.ExternalResourcesRequired');
    var isSvgTransformable =
        predicate((x) => x is svg.Transformable, 'is a svg.Transformable');
    var isSvgLocatable =
        predicate((x) => x is svg.Locatable, 'is a svg.Locatable');
    var isSvgNumber = predicate((x) => x is svg.Number, 'is a svg.Number');
    var isSvgRect = predicate((x) => x is svg.Rect, 'is a svg.Rect');

    test('rect_isChecks', () {
        var div = insertTestDiv();
        var r = document.query('#rect1');

        // Direct inheritance chain
        expect(r, isSvgElement);
        expect(r, isElement);
        expect(r, isNode);

        // Other implemented interfaces.
        expect(r, isSvgTests);
        expect(r, isSvgLangSpace);
        expect(r, isSvgExternalResourcesRequired);
        expect(r, isSvgTransformable);
        expect(r, isSvgLocatable);

        // Interfaces not implemented.
        expect(r, isNot(isSvgNumber));
        expect(r, isNot(isSvgRect));
        expect(r, isNot(isSvgSvgElement));

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
    document.body.nodes.add(element);
    return element;
  }

  group('supported_externalResourcesRequired', () {
    test('supported', () {
      var div = insertTestDiv();
      var r = document.query('#rect1');
      expect(svg.ExternalResourcesRequired.supported(r), true);
      div.remove();
    });
  });

  group('supported_langSpace', () {
    test('supported', () {
      var div = insertTestDiv();
      var r = document.query('#rect1');
      expect(svg.LangSpace.supported(r), true);
      div.remove();
    });
  });

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
    var isSvgAnimatedTransformList =
        predicate((x) => x is svg.AnimatedTransformList,
            'is an svg.AnimatedTransformList');
    var isCssStyleDeclaration =
        predicate((x) => x is CssStyleDeclaration, 'is a CssStyleDeclaration');

    /// Verifies that [e] supports the operations on the svg.Tests interface.
    checkSvgTests(e) {
      // Just check that the operations seem to exist.
      var rx = e.requiredExtensions;
      expect(rx, isStringList);
      var rf = e.requiredFeatures;
      expect(rf, isStringList);
      var sl = e.systemLanguage;
      expect(sl, isStringList);

      bool hasDoDo = e.hasExtension("DoDo");
      expect(hasDoDo, isFalse);
    }

    /// Verifies that [e] supports the operations on the svg.Locatable interface.
    checkSvgLocatable(e) {
      var v1 = e.farthestViewportElement;
      var v2 = e.nearestViewportElement;
      expect(v1, same(v2));

      var bbox = e.getBBox();
      expect(bbox, isSvgRect);

      var ctm = e.getCtm();
      expect(ctm, isSvgMatrix);

      var sctm = e.getScreenCtm();
      expect(sctm, isSvgMatrix);

      var xf2e = e.getTransformToElement(e);
      expect(xf2e, isSvgMatrix);
    }

    /**
     * Verifies that [e] supports the operations on the svg.Transformable
     * interface.
     */
    checkSvgTransformable(e) {
      var trans = e.transform;
      expect(trans, isSvgAnimatedTransformList);
    }

    testRect(name, checker) {
      test(name, () {
        var div = insertTestDiv();
        var r = document.query('#rect1');
        checker(r);
        div.remove();
      });
    }

    /**
     * Verifies that [e] supports the operations on the svg.LangSpace interface.
     */
    checkSvgLangSpace(e) {
      if (svg.LangSpace.supported(e)) {
        // Just check that the attributes seem to exist.
        var lang = e.xmllang;
        e.xmllang = lang;

        String space = e.xmlspace;
        e.xmlspace = space;

        expect(lang, isString);
        expect(space, isString);
      }
    }

    /**
     * Verifies that [e] supports the operations on the
     * svg.ExternalResourcesRequired interface.
     */
    checkSvgExternalResourcesRequired(e) {
      if (svg.ExternalResourcesRequired.supported(e)) {
        var b = e.externalResourcesRequired;
        expect(b, isSvgAnimatedBoolean);
        expect(b.baseVal, isFalse);
        expect(b.animVal, isFalse);
      }
    }

    testRect('rect_SvgTests', checkSvgTests);
    testRect('rect_SvgLangSpace', checkSvgLangSpace);
    testRect('rect_SvgExternalResourcesRequired',
             checkSvgExternalResourcesRequired);
    testRect('rect_SvgLocatable', checkSvgLocatable);
    testRect('rect_SvgTransformable', checkSvgTransformable);
  });

}
