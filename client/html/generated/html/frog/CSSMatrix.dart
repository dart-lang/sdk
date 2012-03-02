
class _CSSMatrixImpl implements CSSMatrix native "*WebKitCSSMatrix" {

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

  _CSSMatrixImpl inverse() native;

  _CSSMatrixImpl multiply(_CSSMatrixImpl secondMatrix) native;

  _CSSMatrixImpl rotate(num rotX, num rotY, num rotZ) native;

  _CSSMatrixImpl rotateAxisAngle(num x, num y, num z, num angle) native;

  _CSSMatrixImpl scale(num scaleX, num scaleY, num scaleZ) native;

  void setMatrixValue(String string) native;

  _CSSMatrixImpl skewX(num angle) native;

  _CSSMatrixImpl skewY(num angle) native;

  String toString() native;

  _CSSMatrixImpl translate(num x, num y, num z) native;
}
