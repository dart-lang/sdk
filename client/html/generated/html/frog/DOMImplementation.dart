
class _DOMImplementationImpl implements DOMImplementation native "*DOMImplementation" {

  _CSSStyleSheetImpl createCSSStyleSheet(String title, String media) native;

  _DocumentImpl createDocument(String namespaceURI, String qualifiedName, _DocumentTypeImpl doctype) => _FixHtmlDocumentReference(_createDocument(namespaceURI, qualifiedName, doctype));

  _EventTargetImpl _createDocument(String namespaceURI, String qualifiedName, _DocumentTypeImpl doctype) native "return this.createDocument(namespaceURI, qualifiedName, doctype);";

  _DocumentTypeImpl createDocumentType(String qualifiedName, String publicId, String systemId) native;

  _DocumentImpl createHTMLDocument(String title) => _FixHtmlDocumentReference(_createHTMLDocument(title));

  _EventTargetImpl _createHTMLDocument(String title) native "return this.createHTMLDocument(title);";

  bool hasFeature(String feature, String version) native;
}
