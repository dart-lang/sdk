
class SVGTransform native "SVGTransform" {

  num angle;

  SVGMatrix matrix;

  int type;

  void setMatrix(SVGMatrix matrix) native;

  void setRotate(num angle, num cx, num cy) native;

  void setScale(num sx, num sy) native;

  void setSkewX(num angle) native;

  void setSkewY(num angle) native;

  void setTranslate(num tx, num ty) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
