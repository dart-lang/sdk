
class _XSLTProcessorImpl extends _DOMTypeBase implements XSLTProcessor {
  _XSLTProcessorImpl._wrap(ptr) : super._wrap(ptr);

  void clearParameters() {
    _ptr.clearParameters();
    return;
  }

  String getParameter(String namespaceURI, String localName) {
    return _wrap(_ptr.getParameter(_unwrap(namespaceURI), _unwrap(localName)));
  }

  void importStylesheet(Node stylesheet) {
    _ptr.importStylesheet(_unwrap(stylesheet));
    return;
  }

  void removeParameter(String namespaceURI, String localName) {
    _ptr.removeParameter(_unwrap(namespaceURI), _unwrap(localName));
    return;
  }

  void reset() {
    _ptr.reset();
    return;
  }

  void setParameter(String namespaceURI, String localName, String value) {
    _ptr.setParameter(_unwrap(namespaceURI), _unwrap(localName), _unwrap(value));
    return;
  }

  Document transformToDocument(Node source) {
    return _FixHtmlDocumentReference(_wrap(_ptr.transformToDocument(_unwrap(source))));
  }

  DocumentFragment transformToFragment(Node source, Document docVal) {
    return _wrap(_ptr.transformToFragment(_unwrap(source), _unwrap(docVal)));
  }
}
