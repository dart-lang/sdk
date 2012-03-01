
class _SVGMatrixImpl implements SVGMatrix native "*SVGMatrix" {

  num a;

  num b;

  num c;

  num d;

  num e;

  num f;

  _SVGMatrixImpl flipX() native;

  _SVGMatrixImpl flipY() native;

  _SVGMatrixImpl inverse() native;

  _SVGMatrixImpl multiply(_SVGMatrixImpl secondMatrix) native;

  _SVGMatrixImpl rotate(num angle) native;

  _SVGMatrixImpl rotateFromVector(num x, num y) native;

  _SVGMatrixImpl scale(num scaleFactor) native;

  _SVGMatrixImpl scaleNonUniform(num scaleFactorX, num scaleFactorY) native;

  _SVGMatrixImpl skewX(num angle) native;

  _SVGMatrixImpl skewY(num angle) native;

  _SVGMatrixImpl translate(num x, num y) native;
}
