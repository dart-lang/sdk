
class WebKitCSSMatrix native "WebKitCSSMatrix" {
  WebKitCSSMatrix([String spec]) native;


  num a;

  num b;

  num c;

  num d;

  num e;

  num f;

  num m11;

  num m12;

  num m13;

  num m14;

  num m21;

  num m22;

  num m23;

  num m24;

  num m31;

  num m32;

  num m33;

  num m34;

  num m41;

  num m42;

  num m43;

  num m44;

  WebKitCSSMatrix inverse() native;

  WebKitCSSMatrix multiply(WebKitCSSMatrix secondMatrix) native;

  WebKitCSSMatrix rotate(num rotX, num rotY, num rotZ) native;

  WebKitCSSMatrix rotateAxisAngle(num x, num y, num z, num angle) native;

  WebKitCSSMatrix scale(num scaleX, num scaleY, num scaleZ) native;

  void setMatrixValue(String string) native;

  WebKitCSSMatrix skewX(num angle) native;

  WebKitCSSMatrix skewY(num angle) native;

  String toString() native;

  WebKitCSSMatrix translate(num x, num y, num z) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
