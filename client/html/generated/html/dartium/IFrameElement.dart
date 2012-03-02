
class _IFrameElementImpl extends _ElementImpl implements IFrameElement {
  _IFrameElementImpl._wrap(ptr) : super._wrap(ptr);

  String get align() => _wrap(_ptr.align);

  void set align(String value) { _ptr.align = _unwrap(value); }

  Document get contentDocument() => _FixHtmlDocumentReference(_wrap(_ptr.contentDocument));

  Window get contentWindow() => _wrap(_ptr.contentWindow);

  String get frameBorder() => _wrap(_ptr.frameBorder);

  void set frameBorder(String value) { _ptr.frameBorder = _unwrap(value); }

  String get height() => _wrap(_ptr.height);

  void set height(String value) { _ptr.height = _unwrap(value); }

  String get longDesc() => _wrap(_ptr.longDesc);

  void set longDesc(String value) { _ptr.longDesc = _unwrap(value); }

  String get marginHeight() => _wrap(_ptr.marginHeight);

  void set marginHeight(String value) { _ptr.marginHeight = _unwrap(value); }

  String get marginWidth() => _wrap(_ptr.marginWidth);

  void set marginWidth(String value) { _ptr.marginWidth = _unwrap(value); }

  String get name() => _wrap(_ptr.name);

  void set name(String value) { _ptr.name = _unwrap(value); }

  String get sandbox() => _wrap(_ptr.sandbox);

  void set sandbox(String value) { _ptr.sandbox = _unwrap(value); }

  String get scrolling() => _wrap(_ptr.scrolling);

  void set scrolling(String value) { _ptr.scrolling = _unwrap(value); }

  String get src() => _wrap(_ptr.src);

  void set src(String value) { _ptr.src = _unwrap(value); }

  String get width() => _wrap(_ptr.width);

  void set width(String value) { _ptr.width = _unwrap(value); }

  SVGDocument getSVGDocument() {
    return _wrap(_ptr.getSVGDocument());
  }
}
