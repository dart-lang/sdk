
class DOMImplementationJs extends DOMTypeJs implements DOMImplementation native "*DOMImplementation" {

  CSSStyleSheetJs createCSSStyleSheet(String title, String media) native;

  DocumentJs createDocument(String namespaceURI, String qualifiedName, DocumentTypeJs doctype) native;

  DocumentTypeJs createDocumentType(String qualifiedName, String publicId, String systemId) native;

  HTMLDocumentJs createHTMLDocument(String title) native;

  bool hasFeature(String feature, String version) native;
}
