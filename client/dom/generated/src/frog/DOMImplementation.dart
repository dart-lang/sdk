
class DOMImplementation native "*DOMImplementation" {

  CSSStyleSheet createCSSStyleSheet(String title, String media) native;

  Document createDocument(String namespaceURI, String qualifiedName, DocumentType doctype) native;

  DocumentType createDocumentType(String qualifiedName, String publicId, String systemId) native;

  HTMLDocument createHTMLDocument(String title) native;

  bool hasFeature(String feature, String version) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
