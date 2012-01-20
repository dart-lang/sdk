
class SVGPatternElement extends SVGElement native "*SVGPatternElement" {

  SVGAnimatedLength get height() native "return this.height;";

  SVGAnimatedEnumeration get patternContentUnits() native "return this.patternContentUnits;";

  SVGAnimatedTransformList get patternTransform() native "return this.patternTransform;";

  SVGAnimatedEnumeration get patternUnits() native "return this.patternUnits;";

  SVGAnimatedLength get width() native "return this.width;";

  SVGAnimatedLength get x() native "return this.x;";

  SVGAnimatedLength get y() native "return this.y;";

  // From SVGURIReference

  SVGAnimatedString get href() native "return this.href;";

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

  // From SVGFitToViewBox

  SVGAnimatedPreserveAspectRatio get preserveAspectRatio() native "return this.preserveAspectRatio;";

  SVGAnimatedRect get viewBox() native "return this.viewBox;";
}
