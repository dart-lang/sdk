
class _SVGPointImpl implements SVGPoint native "*SVGPoint" {

  num x;

  num y;

  _SVGPointImpl matrixTransform(_SVGMatrixImpl matrix) native;
}
