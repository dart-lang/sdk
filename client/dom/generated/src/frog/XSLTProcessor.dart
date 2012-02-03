
class _XSLTProcessorJs extends _DOMTypeJs implements XSLTProcessor native "*XSLTProcessor" {

  void clearParameters() native;

  String getParameter(String namespaceURI, String localName) native;

  void importStylesheet(_NodeJs stylesheet) native;

  void removeParameter(String namespaceURI, String localName) native;

  void reset() native;

  void setParameter(String namespaceURI, String localName, String value) native;

  _DocumentJs transformToDocument(_NodeJs source) native;

  _DocumentFragmentJs transformToFragment(_NodeJs source, _DocumentJs docVal) native;
}
