
class TouchJS implements Touch native "*Touch" {

  int get clientX() native "return this.clientX;";

  int get clientY() native "return this.clientY;";

  int get identifier() native "return this.identifier;";

  int get pageX() native "return this.pageX;";

  int get pageY() native "return this.pageY;";

  int get screenX() native "return this.screenX;";

  int get screenY() native "return this.screenY;";

  EventTargetJS get target() native "return this.target;";

  num get webkitForce() native "return this.webkitForce;";

  int get webkitRadiusX() native "return this.webkitRadiusX;";

  int get webkitRadiusY() native "return this.webkitRadiusY;";

  num get webkitRotationAngle() native "return this.webkitRotationAngle;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
