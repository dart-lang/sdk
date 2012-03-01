
class _CSSValueImpl extends _DOMTypeBase implements CSSValue {
  _CSSValueImpl._wrap(ptr) : super._wrap(ptr);

  String get cssText() => _wrap(_ptr.cssText);

  void set cssText(String value) { _ptr.cssText = _unwrap(value); }

  int get cssValueType() => _wrap(_ptr.cssValueType);
}
