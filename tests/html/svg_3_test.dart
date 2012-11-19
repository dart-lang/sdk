library SVG3Test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';
import 'dart:svg' as svg;

// Test that SVG elements have the operations advertised through all the IDL
// interfaces.  This is a 'duck typing' test, and does not explicitly use 'is'
// checks on the expected interfaces (that is in SVGTest2).

main() {

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
   * Verifies that [e] supports the operations on the svg.Tests interface.
   */
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

  /**
   * Verifies that [e] supports the operations on the svg.LangSpace interface.
   */
  checkSvgLangSpace(e) {
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
   * svg.ExternalResourcesRequired interface.
   */
  checkSvgExternalResourcesRequired(e) {
    var b = e.externalResourcesRequired;
    expect(b, isSvgAnimatedBoolean);
    expect(b.baseVal, isFalse);
    expect(b.animVal, isFalse);
  }

  /**
   * Verifies that [e] supports the operations on the svg.Stylable interface.
   */
  checkSvgStylable(e) {
    var className = e.$dom_svgClassName;
    expect(className, isSvgAnimatedString);

    var s = e.style;
    expect(s, isCSSStyleDeclaration);

    var attributeA = e.getPresentationAttribute('A');
    expect(attributeA, anyOf(isNull, isCSSValue));
  }

  /**
   * Verifies that [e] supports the operations on the svg.Locatable interface.
   */
  checkSvgLocatable(e) {
    var v1 = e.farthestViewportElement;
    var v2 = e.nearestViewportElement;
    expect(v1, same(v2));

    var bbox = e.getBBox();
    expect(bbox, isSvgRect);

    var ctm = e.getCTM();
    expect(ctm, isSvgMatrix);

    var sctm = e.getScreenCTM();
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

  testRect('rect_SvgTests', checkSvgTests);
  testRect('rect_SvgLangSpace', checkSvgLangSpace);
  testRect('rect_SvgExternalResourcesRequired',
           checkSvgExternalResourcesRequired);
  testRect('rect_SvgStylable', checkSvgStylable);
  testRect('rect_SvgLocatable', checkSvgLocatable);
  testRect('rect_SvgTransformable', checkSvgTransformable);

}
