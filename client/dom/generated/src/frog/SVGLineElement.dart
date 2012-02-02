
class _SVGLineElementJs extends _SVGElementJs implements SVGLineElement native "*SVGLineElement" {

  _SVGAnimatedLengthJs get x1() native "return this.x1;";

  _SVGAnimatedLengthJs get x2() native "return this.x2;";

  _SVGAnimatedLengthJs get y1() native "return this.y1;";

  _SVGAnimatedLengthJs get y2() native "return this.y2;";

  // From SVGTests

  _SVGStringListJs get requiredExtensions() native "return this.requiredExtensions;";

  _SVGStringListJs get requiredFeatures() native "return this.requiredFeatures;";

  _SVGStringListJs get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  _SVGAnimatedBooleanJs get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  _SVGAnimatedStringJs get className() native "return this.className;";

  _CSSStyleDeclarationJs get style() native "return this.style;";

  _CSSValueJs getPresentationAttribute(String name) native;

  // From SVGTransformable

  _SVGAnimatedTransformListJs get transform() native "return this.transform;";

  // From SVGLocatable

  _SVGElementJs get farthestViewportElement() native "return this.farthestViewportElement;";

  _SVGElementJs get nearestViewportElement() native "return this.nearestViewportElement;";

  _SVGRectJs getBBox() native;

  _SVGMatrixJs getCTM() native;

  _SVGMatrixJs getScreenCTM() native;

  _SVGMatrixJs getTransformToElement(_SVGElementJs element) native;
}
