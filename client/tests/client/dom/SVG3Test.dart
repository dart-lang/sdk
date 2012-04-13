#library('SVG3Test');
#import('../../../../lib/unittest/unittest.dart');
#import('../../../../lib/unittest/dom_config.dart');
#import('dart:dom');

// Test that SVG elements have the operations advertised through all the IDL
// interfaces.  This is a 'duck typing' test, and does not explicitly use 'is'
// checks on the expected interfaces (that is in SVGTest2).

main() {

  insertTestDiv() {
    var element = document.createElement('div');
    element.innerHTML = @'''
<svg id='svg1' width='200' height='100'>
<rect id='rect1' x='10' y='20' width='130' height='40' rx='5'fill='blue'></rect>
</svg>
''';
    document.body.appendChild(element);
    return element;
  }

  useDomConfiguration();

  /**
   * Verifies that [e] supports the operations on the SVGTests interface.
   */
  checkSVGTests(e) {
    // Just check that the operations seem to exist.
    var rx = e.requiredExtensions;
    Expect.isTrue(rx is SVGStringList);
    var rf = e.requiredFeatures;
    Expect.isTrue(rf is SVGStringList);
    var sl = e.systemLanguage;
    Expect.isTrue(sl is SVGStringList);

    bool hasDoDo = e.hasExtension("DoDo");
    Expect.isFalse(hasDoDo);
  }

  /**
   * Verifies that [e] supports the operations on the SVGLangSpace interface.
   */
  checkSVGLangSpace(e) {
    // Just check that the attribtes seem to exist.
    var lang = e.xmllang;
    e.xmllang = lang;

    String space = e.xmlspace;
    e.xmlspace = space;

    Expect.isTrue(lang is String);
    Expect.isTrue(space is String);
  }

  /**
   * Verifies that [e] supports the operations on the
   * SVGExternalResourcesRequired interface.
   */
  checkSVGExternalResourcesRequired(e) {
    var b = e.externalResourcesRequired;
    Expect.isTrue(b is SVGAnimatedBoolean);
    Expect.isFalse(b.baseVal);
    Expect.isFalse(b.animVal);
  }

  /**
   * Verifies that [e] supports the operations on the SVGStylable interface.
   */
  checkSVGStylable(e) {
    var className = e.className;
    Expect.isTrue(className is SVGAnimatedString);

    var s = e.style;
    Expect.isTrue(s is CSSStyleDeclaration);

    var attributeA = e.getPresentationAttribute('A');
    Expect.isTrue(attributeA === null || attributeA is CSSValue);
  }

  /**
   * Verifies that [e] supports the operations on the SVGLocatable interface.
   */
  checkSVGLocatable(e) {
    var v1 = e.farthestViewportElement;
    var v2 = e.nearestViewportElement;
    Expect.isTrue(v1 === v2);

    var bbox = e.getBBox();
    Expect.isTrue(bbox is SVGRect);

    var ctm = e.getCTM();
    Expect.isTrue(ctm is SVGMatrix);

    var sctm = e.getScreenCTM();
    Expect.isTrue(sctm is SVGMatrix);

    var xf2e = e.getTransformToElement(e);
    Expect.isTrue(xf2e is SVGMatrix);
  }

  /**
   * Verifies that [e] supports the operations on the SVGTransformable
   * interface.
   */
  checkSVGTransformable(e) {
    var trans = e.transform;
    Expect.isTrue(trans is SVGAnimatedTransformList);
  }

  testRect(name, checker) {
    test(name, () {
        var div = insertTestDiv();
        var r = document.getElementById('rect1');
        checker(r);
        document.body.removeChild(div);
      });
  }

  testRect('rect_SVGTests', checkSVGTests);
  testRect('rect_SVGLangSpace', checkSVGLangSpace);
  testRect('rect_SVGExternalResourcesRequired',
           checkSVGExternalResourcesRequired);
  testRect('rect_SVGStylable', checkSVGStylable);
  testRect('rect_SVGLocatable', checkSVGLocatable);
  testRect('rect_SVGTransformable', checkSVGTransformable);

}
