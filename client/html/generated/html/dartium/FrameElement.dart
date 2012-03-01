
class _FrameElementImpl extends _ElementImpl implements FrameElement {
  _FrameElementImpl._wrap(ptr) : super._wrap(ptr);

  Document get contentDocument() => _FixHtmlDocumentReference(_wrap(_ptr.contentDocument));

  Window get contentWindow() => _wrap(_ptr.contentWindow);

  String get frameBorder() => _wrap(_ptr.frameBorder);

  void set frameBorder(String value) { _ptr.frameBorder = _unwrap(value); }

  int get height() => _wrap(_ptr.height);

  String get location() => _wrap(_ptr.location);

  void set location(String value) { _ptr.location = _unwrap(value); }

  String get longDesc() => _wrap(_ptr.longDesc);

  void set longDesc(String value) { _ptr.longDesc = _unwrap(value); }

  String get marginHeight() => _wrap(_ptr.marginHeight);

  void set marginHeight(String value) { _ptr.marginHeight = _unwrap(value); }

  String get marginWidth() => _wrap(_ptr.marginWidth);

  void set marginWidth(String value) { _ptr.marginWidth = _unwrap(value); }

  String get name() => _wrap(_ptr.name);

  void set name(String value) { _ptr.name = _unwrap(value); }

  bool get noResize() => _wrap(_ptr.noResize);

  void set noResize(bool value) { _ptr.noResize = _unwrap(value); }

  String get scrolling() => _wrap(_ptr.scrolling);

  void set scrolling(String value) { _ptr.scrolling = _unwrap(value); }

  String get src() => _wrap(_ptr.src);

  void set src(String value) { _ptr.src = _unwrap(value); }

  int get width() => _wrap(_ptr.width);

  SVGDocument getSVGDocument() {
    return _wrap(_ptr.getSVGDocument());
  }
}
