
class _SVGTransformImpl implements SVGTransform native "*SVGTransform" {

  static final int SVG_TRANSFORM_MATRIX = 1;

  static final int SVG_TRANSFORM_ROTATE = 4;

  static final int SVG_TRANSFORM_SCALE = 3;

  static final int SVG_TRANSFORM_SKEWX = 5;

  static final int SVG_TRANSFORM_SKEWY = 6;

  static final int SVG_TRANSFORM_TRANSLATE = 2;

  static final int SVG_TRANSFORM_UNKNOWN = 0;

  final num angle;

  final _SVGMatrixImpl matrix;

  final int type;

  void setMatrix(_SVGMatrixImpl matrix) native;

  void setRotate(num angle, num cx, num cy) native;

  void setScale(num sx, num sy) native;

  void setSkewX(num angle) native;

  void setSkewY(num angle) native;

  void setTranslate(num tx, num ty) native;
}
