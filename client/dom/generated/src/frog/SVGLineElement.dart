
class SVGLineElementJS extends SVGElementJS implements SVGLineElement native "*SVGLineElement" {

  SVGAnimatedLengthJS get x1() native "return this.x1;";

  SVGAnimatedLengthJS get x2() native "return this.x2;";

  SVGAnimatedLengthJS get y1() native "return this.y1;";

  SVGAnimatedLengthJS get y2() native "return this.y2;";

  // From SVGTests

  SVGStringListJS get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringListJS get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringListJS get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBooleanJS get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedStringJS get className() native "return this.className;";

  CSSStyleDeclarationJS get style() native "return this.style;";

  CSSValueJS getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformListJS get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElementJS get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElementJS get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRectJS getBBox() native;

  SVGMatrixJS getCTM() native;

  SVGMatrixJS getScreenCTM() native;

  SVGMatrixJS getTransformToElement(SVGElementJS element) native;
}
