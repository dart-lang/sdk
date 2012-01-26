
class SVGPatternElementJs extends SVGElementJs implements SVGPatternElement native "*SVGPatternElement" {

  SVGAnimatedLengthJs get height() native "return this.height;";

  SVGAnimatedEnumerationJs get patternContentUnits() native "return this.patternContentUnits;";

  SVGAnimatedTransformListJs get patternTransform() native "return this.patternTransform;";

  SVGAnimatedEnumerationJs get patternUnits() native "return this.patternUnits;";

  SVGAnimatedLengthJs get width() native "return this.width;";

  SVGAnimatedLengthJs get x() native "return this.x;";

  SVGAnimatedLengthJs get y() native "return this.y;";

  // From SVGURIReference

  SVGAnimatedStringJs get href() native "return this.href;";

  // From SVGTests

  SVGStringListJs get requiredExtensions() native "return this.requiredExtensions;";

  SVGStringListJs get requiredFeatures() native "return this.requiredFeatures;";

  SVGStringListJs get systemLanguage() native "return this.systemLanguage;";

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String get xmllang() native "return this.xmllang;";

  void set xmllang(String value) native "this.xmllang = value;";

  String get xmlspace() native "return this.xmlspace;";

  void set xmlspace(String value) native "this.xmlspace = value;";

  // From SVGExternalResourcesRequired

  SVGAnimatedBooleanJs get externalResourcesRequired() native "return this.externalResourcesRequired;";

  // From SVGStylable

  SVGAnimatedStringJs get className() native "return this.className;";

  CSSStyleDeclarationJs get style() native "return this.style;";

  CSSValueJs getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatioJs get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedRectJs get viewBox() native "return this.viewBox;";
}
