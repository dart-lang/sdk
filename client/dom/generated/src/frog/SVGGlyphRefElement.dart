
class SVGGlyphRefElement extends SVGElement native "*SVGGlyphRefElement" {

  num dx;

  num dy;

  String format;

  String glyphRef;

  num x;

  num y;

  // From SVGURIReference

  SVGAnimatedString href;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}
