
class SVGFEMorphologyElement extends SVGElement native "SVGFEMorphologyElement" {

  SVGAnimatedString in1;

  SVGAnimatedEnumeration operator;

  SVGAnimatedNumber radiusX;

  SVGAnimatedNumber radiusY;

  void setRadius(num radiusX, num radiusY) native;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength height;

  SVGAnimatedString result;

  SVGAnimatedLength width;

  SVGAnimatedLength x;

  SVGAnimatedLength y;

  // From SVGStylable

  SVGAnimatedString className;

  CSSStyleDeclaration style;

  CSSValue getPresentationAttribute(String name) native;
}
