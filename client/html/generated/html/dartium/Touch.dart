
class _TouchImpl extends _DOMTypeBase implements Touch {
  _TouchImpl._wrap(ptr) : super._wrap(ptr);

  int get clientX() => _wrap(_ptr.clientX);

  int get clientY() => _wrap(_ptr.clientY);

  int get identifier() => _wrap(_ptr.identifier);

  int get pageX() => _wrap(_ptr.pageX);

  int get pageY() => _wrap(_ptr.pageY);

  int get screenX() => _wrap(_ptr.screenX);

  int get screenY() => _wrap(_ptr.screenY);

  EventTarget get target() => _FixHtmlDocumentReference(_wrap(_ptr.target));

  num get webkitForce() => _wrap(_ptr.webkitForce);

  int get webkitRadiusX() => _wrap(_ptr.webkitRadiusX);

  int get webkitRadiusY() => _wrap(_ptr.webkitRadiusY);

  num get webkitRotationAngle() => _wrap(_ptr.webkitRotationAngle);
}
