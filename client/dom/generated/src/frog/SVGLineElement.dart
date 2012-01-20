
class SVGLineElement extends SVGElement native "*SVGLineElement" {

  SVGAnimatedLength get x1() native "return this.x1;";

  SVGAnimatedLength get x2() native "return this.x2;";

  SVGAnimatedLength get y1() native "return this.y1;";

  SVGAnimatedLength get y2() native "return this.y2;";

  // From SVGTests

  SVGStringList get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringList get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringList get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  // From SVGTransformable

  SVGAnimatedTransformList get transform() native "return this.transform;";

  // From SVGLocatable

  SVGElement get farthestViewportElement() native "return this.farthestViewportElement;";

  SVGElement get nearestViewportElement() native "return this.nearestViewportElement;";

  SVGRect getBBox() native;

  SVGMatrix getCTM() native;

  SVGMatrix getScreenCTM() native;

  SVGMatrix getTransformToElement(SVGElement element) native;
}
