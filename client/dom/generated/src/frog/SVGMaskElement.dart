
class SVGMaskElementJS extends SVGElementJS implements SVGMaskElement native "*SVGMaskElement" {

  SVGAnimatedLengthJS get height() native "return this.height;";

  SVGAnimatedEnumerationJS get maskContentUnits() native "return this.maskContentUnits;";

  SVGAnimatedEnumerationJS get maskUnits() native "return this.maskUnits;";

  SVGAnimatedLengthJS get width() native "return this.width;";

  SVGAnimatedLengthJS get x() native "return this.x;";

  SVGAnimatedLengthJS get y() native "return this.y;";

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
}
