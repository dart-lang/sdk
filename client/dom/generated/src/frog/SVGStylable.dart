
class SVGStylableJS implements SVGStylable native "*SVGStylable" {

  SVGAnimatedStringJS get className() native "return this.className;";

  CSSStyleDeclarationJS get style() native "return this.style;";

  CSSValueJS getPresentationAttribute(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
