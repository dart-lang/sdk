
class SVGPoint native "*SVGPoint" {

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";

  SVGPoint matrixTransform(SVGMatrix matrix) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
