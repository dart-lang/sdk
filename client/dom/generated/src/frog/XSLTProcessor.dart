
class XSLTProcessor native "*XSLTProcessor" {

  void clearParameters() native;

  String getParameter(String namespaceURI, String localName) native;

  void importStylesheet(Node stylesheet) native;

  void removeParameter(String namespaceURI, String localName) native;

  void reset() native;

  void setParameter(String namespaceURI, String localName, String value) native;

  Document transformToDocument(Node source) native;

  DocumentFragment transformToFragment(Node source, Document docVal) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
