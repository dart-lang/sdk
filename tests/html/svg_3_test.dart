library SVG3Test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';
import 'dart:svg';

// Test that SVG elements have the operations advertised through all the IDL
// interfaces.  This is a 'duck typing' test, and does not explicitly use 'is'
// checks on the expected interfaces (that is in SVGTest2).

main() {

  var isString = predicate((x) => x is String, 'is a String');
  var isStringList = predicate((x) => x is List<String>, 'is a List<String>');
  var isSVGMatrix = predicate((x) => x is SVGMatrix, 'is a SVGMatrix');
  var isSVGAnimatedBoolean =
      predicate((x) => x is SVGAnimatedBoolean, 'is an SVGAnimatedBoolean');
  var isSVGAnimatedString =
      predicate((x) => x is SVGAnimatedString, 'is an SVGAnimatedString');
  var isSVGRect = predicate((x) => x is SVGRect, 'is a SVGRect');
  var isSVGAnimatedTransformList =
      predicate((x) => x is SVGAnimatedTransformList,
          'is an SVGAnimatedTransformList');
  var isCSSStyleDeclaration =
      predicate((x) => x is CSSStyleDeclaration, 'is a CSSStyleDeclaration');
  var isCSSValue = predicate((x) => x is CSSValue, 'is a CSSValue');

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

  /**
   * Verifies that [e] supports the operations on the SVGTests interface.
   */
  checkSVGTests(e) {
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

  /**
   * Verifies that [e] supports the operations on the SVGLangSpace interface.
   */
  checkSVGLangSpace(e) {
    // Just check that the attribtes seem to exist.
    var lang = e.xmllang;
    e.xmllang = lang;

    String space = e.xmlspace;
    e.xmlspace = space;

    expect(lang, isString);
    expect(space, isString);
  }

  /**
   * Verifies that [e] supports the operations on the
   * SVGExternalResourcesRequired interface.
   */
  checkSVGExternalResourcesRequired(e) {
    var b = e.externalResourcesRequired;
    expect(b, isSVGAnimatedBoolean);
    expect(b.baseVal, isFalse);
    expect(b.animVal, isFalse);
  }

  /**
   * Verifies that [e] supports the operations on the SVGStylable interface.
   */
  checkSVGStylable(e) {
    var className = e.$dom_svgClassName;
    expect(className, isSVGAnimatedString);

    var s = e.style;
    expect(s, isCSSStyleDeclaration);

    var attributeA = e.getPresentationAttribute('A');
    expect(attributeA, anyOf(isNull, isCSSValue));
  }

  /**
   * Verifies that [e] supports the operations on the SVGLocatable interface.
   */
  checkSVGLocatable(e) {
    var v1 = e.farthestViewportElement;
    var v2 = e.nearestViewportElement;
    expect(v1, same(v2));

    var bbox = e.getBBox();
    expect(bbox, isSVGRect);

    var ctm = e.getCTM();
    expect(ctm, isSVGMatrix);

    var sctm = e.getScreenCTM();
    expect(sctm, isSVGMatrix);

    var xf2e = e.getTransformToElement(e);
    expect(xf2e, isSVGMatrix);
  }

  /**
   * Verifies that [e] supports the operations on the SVGTransformable
   * interface.
   */
  checkSVGTransformable(e) {
    var trans = e.transform;
    expect(trans, isSVGAnimatedTransformList);
  }

  testRect(name, checker) {
    test(name, () {
        var div = insertTestDiv();
        var r = document.query('#rect1');
        checker(r);
        div.remove();
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
