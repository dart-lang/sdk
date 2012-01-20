
class SVGRect native "*SVGRect" {

  num get height() native "return this.height;";

  void set height(num value) native "this.height = value;";

  num get width() native "return this.width;";

  void set width(num value) native "this.width = value;";

  num get x() native "return this.x;";

  void set x(num value) native "this.x = value;";

  num get y() native "return this.y;";

  void set y(num value) native "this.y = value;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
