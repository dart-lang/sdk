
class _RGBColorImpl extends _DOMTypeBase implements RGBColor {
  _RGBColorImpl._wrap(ptr) : super._wrap(ptr);

  CSSPrimitiveValue get blue() => _wrap(_ptr.blue);

  CSSPrimitiveValue get green() => _wrap(_ptr.green);

  CSSPrimitiveValue get red() => _wrap(_ptr.red);
}
