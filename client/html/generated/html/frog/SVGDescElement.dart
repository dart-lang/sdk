
class _SVGDescElementImpl extends _SVGElementImpl implements SVGDescElement native "*SVGDescElement" {

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGStylable

  _SVGAnimatedStringImpl get _svgClassName() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}
