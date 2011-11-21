
class SVGMatrix native "SVGMatrix" {

  num a;

  num b;

  num c;

  num d;

  num e;

  num f;

  SVGMatrix flipX() native;

  SVGMatrix flipY() native;

  SVGMatrix inverse() native;

  SVGMatrix multiply(SVGMatrix secondMatrix) native;

  SVGMatrix rotate(num angle) native;

  SVGMatrix rotateFromVector(num x, num y) native;

  SVGMatrix scale(num scaleFactor) native;

  SVGMatrix scaleNonUniform(num scaleFactorX, num scaleFactorY) native;

  SVGMatrix skewX(num angle) native;

  SVGMatrix skewY(num angle) native;

  SVGMatrix translate(num x, num y) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
