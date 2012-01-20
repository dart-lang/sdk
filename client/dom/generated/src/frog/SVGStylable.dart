
class SVGStylable native "*SVGStylable" {

  SVGAnimatedString get className() native "return this.className;";

  CSSStyleDeclaration get style() native "return this.style;";

  CSSValue getPresentationAttribute(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
