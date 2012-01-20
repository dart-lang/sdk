
class SVGMatrix native "*SVGMatrix" {

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

  SVGMatrix flipX() native;

  SVGMatrix flipY() native;

  SVGMatrix inverse() native;

  SVGMatrix multiply(SVGMatrix secondMatrix) native;

  SVGMatrix rotate(num angle) native;

  SVGMatrix rotateFromVector(num x, num y) native;

  SVGMatrix scale(num scaleFactor) native;

  SVGMatrix scaleNonUniform(num scaleFactorX, num scaleFactorY) native;

  SVGMatrix skewX(num angle) native;

  SVGMatrix skewY(num angle) native;

  SVGMatrix translate(num x, num y) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
