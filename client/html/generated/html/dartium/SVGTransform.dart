
class _SVGTransformImpl extends _DOMTypeBase implements SVGTransform {
  _SVGTransformImpl._wrap(ptr) : super._wrap(ptr);

  num get angle() => _wrap(_ptr.angle);

  SVGMatrix get matrix() => _wrap(_ptr.matrix);

  int get type() => _wrap(_ptr.type);

  void setMatrix(SVGMatrix matrix) {
    _ptr.setMatrix(_unwrap(matrix));
    return;
  }

  void setRotate(num angle, num cx, num cy) {
    _ptr.setRotate(_unwrap(angle), _unwrap(cx), _unwrap(cy));
    return;
  }

  void setScale(num sx, num sy) {
    _ptr.setScale(_unwrap(sx), _unwrap(sy));
    return;
  }

  void setSkewX(num angle) {
    _ptr.setSkewX(_unwrap(angle));
    return;
  }

  void setSkewY(num angle) {
    _ptr.setSkewY(_unwrap(angle));
    return;
  }

  void setTranslate(num tx, num ty) {
    _ptr.setTranslate(_unwrap(tx), _unwrap(ty));
    return;
  }
}
