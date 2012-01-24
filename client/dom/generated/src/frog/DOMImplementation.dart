
class DOMImplementationJS implements DOMImplementation native "*DOMImplementation" {

  CSSStyleSheetJS createCSSStyleSheet(String title, String media) native;

  DocumentJS createDocument(String namespaceURI, String qualifiedName, DocumentTypeJS doctype) native;

  DocumentTypeJS createDocumentType(String qualifiedName, String publicId, String systemId) native;

  HTMLDocumentJS createHTMLDocument(String title) native;

  bool hasFeature(String feature, String version) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
