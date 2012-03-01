
class _SVGElementImpl extends _ElementImpl implements SVGElement {
  _SVGElementImpl._wrap(ptr) : super._wrap(ptr);

  String get id() => _wrap(_ptr.id);

  void set id(String value) { _ptr.id = _unwrap(value); }

  SVGSVGElement get ownerSVGElement() => _wrap(_ptr.ownerSVGElement);

  SVGElement get viewportElement() => _wrap(_ptr.viewportElement);

  String get xmlbase() => _wrap(_ptr.xmlbase);

  void set xmlbase(String value) { _ptr.xmlbase = _unwrap(value); }
}
