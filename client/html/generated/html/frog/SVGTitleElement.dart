
class _SVGTitleElementImpl extends _SVGElementImpl implements SVGTitleElement native "*SVGTitleElement" {

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGStylable

  _SVGAnimatedStringImpl get _svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}
