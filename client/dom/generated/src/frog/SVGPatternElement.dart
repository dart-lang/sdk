
class _SVGPatternElementJs extends _SVGElementJs implements SVGPatternElement native "*SVGPatternElement" {

  _SVGAnimatedLengthJs get height() native "return this.height;";

  _SVGAnimatedEnumerationJs get patternContentUnits() native "return this.patternContentUnits;";

  _SVGAnimatedTransformListJs get patternTransform() native "return this.patternTransform;";

  _SVGAnimatedEnumerationJs get patternUnits() native "return this.patternUnits;";

  _SVGAnimatedLengthJs get width() native "return this.width;";

  _SVGAnimatedLengthJs get x() native "return this.x;";

  _SVGAnimatedLengthJs get y() native "return this.y;";

  // From SVGURIReference

  _SVGAnimatedStringJs get href() native "return this.href;";

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

  // From SVGFitToViewBox

  _SVGAnimatedPreserveAspectRatioJs get preserveAspectRatio() native "return this.preserveAspectRatio;";

  _SVGAnimatedRectJs get viewBox() native "return this.viewBox;";
}
