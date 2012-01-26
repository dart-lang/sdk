
class SVGPointJs extends DOMTypeJs implements SVGPoint native "*SVGPoint" {

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";

  SVGPointJs matrixTransform(SVGMatrixJs matrix) native;
}
