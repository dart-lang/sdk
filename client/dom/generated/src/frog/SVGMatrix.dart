
class _SVGMatrixJs extends _DOMTypeJs implements SVGMatrix native "*SVGMatrix" {

  num a;

  num b;

  num c;

  num d;

  num e;

  num f;

  _SVGMatrixJs flipX() native;

  _SVGMatrixJs flipY() native;

  _SVGMatrixJs inverse() native;

  _SVGMatrixJs multiply(_SVGMatrixJs secondMatrix) native;

  _SVGMatrixJs rotate(num angle) native;

  _SVGMatrixJs rotateFromVector(num x, num y) native;

  _SVGMatrixJs scale(num scaleFactor) native;

  _SVGMatrixJs scaleNonUniform(num scaleFactorX, num scaleFactorY) native;

  _SVGMatrixJs skewX(num angle) native;

  _SVGMatrixJs skewY(num angle) native;

  _SVGMatrixJs translate(num x, num y) native;
}
