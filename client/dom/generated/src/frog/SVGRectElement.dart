
class _SVGRectElementJs extends _SVGElementJs implements SVGRectElement native "*SVGRectElement" {

  _SVGAnimatedLengthJs get height() native "return this.height;";

  _SVGAnimatedLengthJs get rx() native "return this.rx;";

  _SVGAnimatedLengthJs get ry() native "return this.ry;";

  _SVGAnimatedLengthJs get width() native "return this.width;";

  _SVGAnimatedLengthJs get x() native "return this.x;";

  _SVGAnimatedLengthJs get y() native "return this.y;";

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
