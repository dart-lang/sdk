
class _DOMImplementationImpl extends _DOMTypeBase implements DOMImplementation {
  _DOMImplementationImpl._wrap(ptr) : super._wrap(ptr);

  CSSStyleSheet createCSSStyleSheet(String title, String media) {
    return _wrap(_ptr.createCSSStyleSheet(_unwrap(title), _unwrap(media)));
  }

  Document createDocument(String namespaceURI, String qualifiedName, DocumentType doctype) {
    return _FixHtmlDocumentReference(_wrap(_ptr.createDocument(_unwrap(namespaceURI), _unwrap(qualifiedName), _unwrap(doctype))));
  }

  DocumentType createDocumentType(String qualifiedName, String publicId, String systemId) {
    return _wrap(_ptr.createDocumentType(_unwrap(qualifiedName), _unwrap(publicId), _unwrap(systemId)));
  }

  Document createHTMLDocument(String title) {
    return _FixHtmlDocumentReference(_wrap(_ptr.createHTMLDocument(_unwrap(title))));
  }

  bool hasFeature(String feature, String version) {
    return _wrap(_ptr.hasFeature(_unwrap(feature), _unwrap(version)));
  }
}
