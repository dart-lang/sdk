
class SVGFEMorphologyElement extends SVGElement native "*SVGFEMorphologyElement" {

  static final int SVG_MORPHOLOGY_OPERATOR_DILATE = 2;

  static final int SVG_MORPHOLOGY_OPERATOR_ERODE = 1;

  static final int SVG_MORPHOLOGY_OPERATOR_UNKNOWN = 0;

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
