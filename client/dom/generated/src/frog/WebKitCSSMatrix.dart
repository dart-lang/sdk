
class WebKitCSSMatrix native "*WebKitCSSMatrix" {
  WebKitCSSMatrix([String spec]) native;


  num get a() native "return this.a;";

  void set a(num value) native "this.a = value;";

  num get b() native "return this.b;";

  void set b(num value) native "this.b = value;";

  num get c() native "return this.c;";

  void set c(num value) native "this.c = value;";

  num get d() native "return this.d;";

  void set d(num value) native "this.d = value;";

  num get e() native "return this.e;";

  void set e(num value) native "this.e = value;";

  num get f() native "return this.f;";

  void set f(num value) native "this.f = value;";

  num get m11() native "return this.m11;";

  void set m11(num value) native "this.m11 = value;";

  num get m12() native "return this.m12;";

  void set m12(num value) native "this.m12 = value;";

  num get m13() native "return this.m13;";

  void set m13(num value) native "this.m13 = value;";

  num get m14() native "return this.m14;";

  void set m14(num value) native "this.m14 = value;";

  num get m21() native "return this.m21;";

  void set m21(num value) native "this.m21 = value;";

  num get m22() native "return this.m22;";

  void set m22(num value) native "this.m22 = value;";

  num get m23() native "return this.m23;";

  void set m23(num value) native "this.m23 = value;";

  num get m24() native "return this.m24;";

  void set m24(num value) native "this.m24 = value;";

  num get m31() native "return this.m31;";

  void set m31(num value) native "this.m31 = value;";

  num get m32() native "return this.m32;";

  void set m32(num value) native "this.m32 = value;";

  num get m33() native "return this.m33;";

  void set m33(num value) native "this.m33 = value;";

  num get m34() native "return this.m34;";

  void set m34(num value) native "this.m34 = value;";

  num get m41() native "return this.m41;";

  void set m41(num value) native "this.m41 = value;";

  num get m42() native "return this.m42;";

  void set m42(num value) native "this.m42 = value;";

  num get m43() native "return this.m43;";

  void set m43(num value) native "this.m43 = value;";

  num get m44() native "return this.m44;";

  void set m44(num value) native "this.m44 = value;";

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
