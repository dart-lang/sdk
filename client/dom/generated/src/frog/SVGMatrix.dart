
class SVGMatrixJS implements SVGMatrix native "*SVGMatrix" {

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

  SVGMatrixJS flipX() native;

  SVGMatrixJS flipY() native;

  SVGMatrixJS inverse() native;

  SVGMatrixJS multiply(SVGMatrixJS secondMatrix) native;

  SVGMatrixJS rotate(num angle) native;

  SVGMatrixJS rotateFromVector(num x, num y) native;

  SVGMatrixJS scale(num scaleFactor) native;

  SVGMatrixJS scaleNonUniform(num scaleFactorX, num scaleFactorY) native;

  SVGMatrixJS skewX(num angle) native;

  SVGMatrixJS skewY(num angle) native;

  SVGMatrixJS translate(num x, num y) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
