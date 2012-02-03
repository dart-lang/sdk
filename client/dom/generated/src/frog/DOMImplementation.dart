
class _DOMImplementationJs extends _DOMTypeJs implements DOMImplementation native "*DOMImplementation" {

  _CSSStyleSheetJs createCSSStyleSheet(String title, String media) native;

  _DocumentJs createDocument(String namespaceURI, String qualifiedName, _DocumentTypeJs doctype) native;

  _DocumentTypeJs createDocumentType(String qualifiedName, String publicId, String systemId) native;

  _HTMLDocumentJs createHTMLDocument(String title) native;

  bool hasFeature(String feature, String version) native;
}
