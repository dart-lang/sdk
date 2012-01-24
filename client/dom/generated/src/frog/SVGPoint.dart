
class SVGPointJS implements SVGPoint native "*SVGPoint" {

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";

  SVGPointJS matrixTransform(SVGMatrixJS matrix) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
