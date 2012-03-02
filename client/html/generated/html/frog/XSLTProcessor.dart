
class _XSLTProcessorImpl implements XSLTProcessor native "*XSLTProcessor" {

  void clearParameters() native;

  String getParameter(String namespaceURI, String localName) native;

  void importStylesheet(_NodeImpl stylesheet) native;

  void removeParameter(String namespaceURI, String localName) native;

  void reset() native;

  void setParameter(String namespaceURI, String localName, String value) native;

  _DocumentImpl transformToDocument(_NodeImpl source) => _FixHtmlDocumentReference(_transformToDocument(source));

  _EventTargetImpl _transformToDocument(_NodeImpl source) native "return this.transformToDocument(source);";

  _DocumentFragmentImpl transformToFragment(_NodeImpl source, _DocumentImpl docVal) native;
}
