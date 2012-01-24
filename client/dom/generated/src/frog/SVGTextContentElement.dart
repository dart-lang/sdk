
class SVGTextContentElementJS extends SVGElementJS implements SVGTextContentElement native "*SVGTextContentElement" {

  static final int LENGTHADJUST_SPACING = 1;

  static final int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  static final int LENGTHADJUST_UNKNOWN = 0;

  SVGAnimatedEnumerationJS get lengthAdjust() native "return this.lengthAdjust;";

  SVGAnimatedLengthJS get textLength() native "return this.textLength;";

  int getCharNumAtPosition(SVGPointJS point) native;

  num getComputedTextLength() native;

  SVGPointJS getEndPositionOfChar(int offset) native;

  SVGRectJS getExtentOfChar(int offset) native;

  int getNumberOfChars() native;

  num getRotationOfChar(int offset) native;

  SVGPointJS getStartPositionOfChar(int offset) native;

  num getSubStringLength(int offset, int length) native;

  void selectSubString(int offset, int length) native;

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
