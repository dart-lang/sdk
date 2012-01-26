
class SVGMatrixJs extends DOMTypeJs implements SVGMatrix native "*SVGMatrix" {

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

  SVGMatrixJs flipX() native;

  SVGMatrixJs flipY() native;

  SVGMatrixJs inverse() native;

  SVGMatrixJs multiply(SVGMatrixJs secondMatrix) native;

  SVGMatrixJs rotate(num angle) native;

  SVGMatrixJs rotateFromVector(num x, num y) native;

  SVGMatrixJs scale(num scaleFactor) native;

  SVGMatrixJs scaleNonUniform(num scaleFactorX, num scaleFactorY) native;

  SVGMatrixJs skewX(num angle) native;

  SVGMatrixJs skewY(num angle) native;

  SVGMatrixJs translate(num x, num y) native;
}
