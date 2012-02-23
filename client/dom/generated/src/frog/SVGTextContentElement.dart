
class _SVGTextContentElementJs extends _SVGElementJs implements SVGTextContentElement native "*SVGTextContentElement" {

  static final int LENGTHADJUST_SPACING = 1;

  static final int LENGTHADJUST_SPACINGANDGLYPHS = 2;

  static final int LENGTHADJUST_UNKNOWN = 0;

  final _SVGAnimatedEnumerationJs lengthAdjust;

  final _SVGAnimatedLengthJs textLength;

  int getCharNumAtPosition(_SVGPointJs point) native;

  num getComputedTextLength() native;

  _SVGPointJs getEndPositionOfChar(int offset) native;

  _SVGRectJs getExtentOfChar(int offset) native;

  int getNumberOfChars() native;

  num getRotationOfChar(int offset) native;

  _SVGPointJs getStartPositionOfChar(int offset) native;

  num getSubStringLength(int offset, int length) native;

  void selectSubString(int offset, int length) native;

  // From SVGTests

  final _SVGStringListJs requiredExtensions;

  final _SVGStringListJs requiredFeatures;

  final _SVGStringListJs systemLanguage;

  bool hasExtension(String extension) native;

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanJs externalResourcesRequired;

  // From SVGStylable

  final _SVGAnimatedStringJs className;

  // Use implementation from Element.
  // final _CSSStyleDeclarationJs style;

  _CSSValueJs getPresentationAttribute(String name) native;
}
