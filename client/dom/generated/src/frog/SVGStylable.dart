
class SVGStylable native "SVGStylable" {

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
