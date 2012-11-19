library SVG2Test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';
import 'dart:svg' as svg;

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
  var isSvgElement = predicate((x) => x is svg.SvgElement, 'is a SvgElement');
  var isSvgSvgElement =
      predicate((x) => x is svg.SvgSvgElement, 'is a SvgSvgElement');
  var isNode = predicate((x) => x is Node, 'is a Node');
  var isSvgTests = predicate((x) => x is svg.Tests, 'is a svg.Tests');
  var isSvgLangSpace = predicate((x) => x is svg.LangSpace, 'is a svg.LangSpace');
  var isSvgExternalResourcesRequired =
      predicate((x) => x is svg.ExternalResourcesRequired,
          'is a svg.ExternalResourcesRequired');
  var isSvgStylable = predicate((x) => x is svg.Stylable, 'is a svg.Stylable');
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
      expect(r, isSvgStylable);
      expect(r, isSvgTransformable);
      expect(r, isSvgLocatable);

      // Interfaces not implemented.
      expect(r, isNot(isSvgNumber));
      expect(r, isNot(isSvgRect));
      expect(r, isNot(isSvgSvgElement));

      div.remove();
    });
}
