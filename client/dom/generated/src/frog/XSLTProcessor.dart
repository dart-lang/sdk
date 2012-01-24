
class XSLTProcessorJS implements XSLTProcessor native "*XSLTProcessor" {

  void clearParameters() native;

  String getParameter(String namespaceURI, String localName) native;

  void importStylesheet(NodeJS stylesheet) native;

  void removeParameter(String namespaceURI, String localName) native;

  void reset() native;

  void setParameter(String namespaceURI, String localName, String value) native;

  DocumentJS transformToDocument(NodeJS source) native;

  DocumentFragmentJS transformToFragment(NodeJS source, DocumentJS docVal) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
