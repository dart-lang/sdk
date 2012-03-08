
class _SVGStylableImpl implements SVGStylable native "*SVGStylable" {

  _SVGAnimatedStringImpl get _svgClassName() native "return this.className;";

  final _CSSStyleDeclarationImpl style;

  _CSSValueImpl getPresentationAttribute(String name) native;
}
