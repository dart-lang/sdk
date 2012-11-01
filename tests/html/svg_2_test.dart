library SVG2Test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';

// Test that SVG elements explicitly implement the IDL interfaces (is-checks
// only, see SVGTest3 for behavioural tests).

main() {

  insertTestDiv() {
    var element = new Element.tag('div');
    element.innerHTML = r'''
<svg id='svg1' width='200' height='100'>
<rect id='rect1' x='10' y='20' width='130' height='40' rx='5'fill='blue'></rect>
</svg>
''';
    document.body.nodes.add(element);
    return element;
  }

  useHtmlConfiguration();

  var isElement = predicate((x) => x is Element, 'is an Element');
  var isSVGElement = predicate((x) => x is SVGElement, 'is a SVGElement');
  var isSVGSVGElement =
      predicate((x) => x is SVGSVGElement, 'is a SVGSVGElement');
  var isNode = predicate((x) => x is Node, 'is a Node');
  var isSVGTests = predicate((x) => x is SVGTests, 'is a SVGTests');
  var isSVGLangSpace = predicate((x) => x is SVGLangSpace, 'is a SVGLangSpace');
  var isSVGExternalResourcesRequired =
      predicate((x) => x is SVGExternalResourcesRequired,
          'is a SVGExternalResourcesRequired');
  var isSVGStylable = predicate((x) => x is SVGStylable, 'is a SVGStylable');
  var isSVGTransformable =
      predicate((x) => x is SVGTransformable, 'is a SVGTransformable');
  var isSVGLocatable = predicate((x) => x is SVGLocatable, 'is a SVGLocatable');
  var isSVGNumber = predicate((x) => x is SVGNumber, 'is a SVGNumber');
  var isSVGRect = predicate((x) => x is SVGRect, 'is a SVGRect');

  test('rect_isChecks', () {
      var div = insertTestDiv();
      var r = document.query('#rect1');

      // Direct inheritance chain
      expect(r, isSVGElement);
      expect(r, isElement);
      expect(r, isNode);

      // Other implemented interfaces.
      expect(r, isSVGTests);
      expect(r, isSVGLangSpace);
      expect(r, isSVGExternalResourcesRequired);
      expect(r, isSVGStylable);
      expect(r, isSVGTransformable);
      expect(r, isSVGLocatable);

      // Interfaces not implemented.
      expect(r, isNot(isSVGNumber));
      expect(r, isNot(isSVGRect));
      expect(r, isNot(isSVGSVGElement));

      div.remove();
    });
}
