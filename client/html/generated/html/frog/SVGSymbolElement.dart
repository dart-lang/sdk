
class _SVGSymbolElementImpl extends _SVGElementImpl implements SVGSymbolElement native "*SVGSymbolElement" {

  // From SVGLangSpace

  String xmllang;

  String xmlspace;

  // From SVGExternalResourcesRequired

  final _SVGAnimatedBooleanImpl externalResourcesRequired;

  // From SVGStylable

  _SVGAnimatedStringImpl get _className() native "return this.className;";

  // Use implementation from Element.
  // final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;

  // From SVGFitToViewBox

  final _SVGAnimatedPreserveAspectRatioImpl preserveAspectRatio;

  final _SVGAnimatedRectImpl viewBox;
}
