#library('SVG2Test');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

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

  test('rect_isChecks', () {
      var div = insertTestDiv();
      var r = document.query('#rect1');

      // Direct inheritance chain
      Expect.isTrue(r is SVGElement);
      Expect.isTrue(r is Element);
      Expect.isTrue(r is Node);

      // Other implemented interfaces.
      Expect.isTrue(r is SVGTests);
      Expect.isTrue(r is SVGLangSpace);
      Expect.isTrue(r is SVGExternalResourcesRequired);
      Expect.isTrue(r is SVGStylable);
      Expect.isTrue(r is SVGTransformable);
      Expect.isTrue(r is SVGLocatable);

      // Interfaces not implemented.
      Expect.isFalse(r is SVGNumber);
      Expect.isFalse(r is SVGRect);
      Expect.isFalse(r is SVGSVGElement);

      div.remove();
    });
}
