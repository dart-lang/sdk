
class SVGTextContentElement extends SVGElement native "SVGTextContentElement" {

  static final int LENGTHADJUST_SPACING = 1;

  static final int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  static final int LENGTHADJUST_UNKNOWN = 0;

  SVGAnimatedEnumeration lengthAdjust;

  SVGAnimatedLength textLength;

  int getCharNumAtPosition(SVGPoint point) native;

  num getComputedTextLength() native;

  SVGPoint getEndPositionOfChar(int offset) native;

  SVGRect getExtentOfChar(int offset) native;

  int getNumberOfChars() native;

  num getRotationOfChar(int offset) native;

  SVGPoint getStartPositionOfChar(int offset) native;

  num getSubStringLength(int offset, int length) native;

  void selectSubString(int offset, int length) native;

  // From SVGTests

  SVGStringList requiredExtensions;

  SVGStringList requiredFeatures;

  SVGStringList systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean externalResourcesRequired;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}
