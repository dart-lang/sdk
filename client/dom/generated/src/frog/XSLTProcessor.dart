
class XSLTProcessorJs extends DOMTypeJs implements XSLTProcessor native "*XSLTProcessor" {

  void clearParameters() native;

  String getParameter(String namespaceURI, String localName) native;

  void importStylesheet(NodeJs stylesheet) native;

  void removeParameter(String namespaceURI, String localName) native;

  void reset() native;

  void setParameter(String namespaceURI, String localName, String value) native;

  DocumentJs transformToDocument(NodeJs source) native;

  DocumentFragmentJs transformToFragment(NodeJs source, DocumentJs docVal) native;
}
