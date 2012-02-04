
class _NodeJs extends _DOMTypeJs implements Node native "*Node" {

  static final int ATTRIBUTE_NODE = 2;

  static final int CDATA_SECTION_NODE = 4;

  static final int COMMENT_NODE = 8;

  static final int DOCUMENT_FRAGMENT_NODE = 11;

  static final int DOCUMENT_NODE = 9;

  static final int DOCUMENT_POSITION_CONTAINED_BY = 0x10;

  static final int DOCUMENT_POSITION_CONTAINS = 0x08;

  static final int DOCUMENT_POSITION_DISCONNECTED = 0x01;

  static final int DOCUMENT_POSITION_FOLLOWING = 0x04;

  static final int DOCUMENT_POSITION_IMPLEMENTATION_SPECIFIC = 0x20;

  static final int DOCUMENT_POSITION_PRECEDING = 0x02;

  static final int DOCUMENT_TYPE_NODE = 10;

  static final int ELEMENT_NODE = 1;

  static final int ENTITY_NODE = 6;

  static final int ENTITY_REFERENCE_NODE = 5;

  static final int NOTATION_NODE = 12;

  static final int PROCESSING_INSTRUCTION_NODE = 7;

  static final int TEXT_NODE = 3;

  final _NamedNodeMapJs attributes;

  final String baseURI;

  final _NodeListJs childNodes;

  final _NodeJs firstChild;

  final _NodeJs lastChild;

  final String localName;

  final String namespaceURI;

  final _NodeJs nextSibling;

  final String nodeName;

  final int nodeType;

  String nodeValue;

  final _DocumentJs ownerDocument;

  final _ElementJs parentElement;

  final _NodeJs parentNode;

  String prefix;

  final _NodeJs previousSibling;

  String textContent;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  _NodeJs appendChild(_NodeJs newChild) native;

  _NodeJs cloneNode(bool deep) native;

  int compareDocumentPosition(_NodeJs other) native;

  bool contains(_NodeJs other) native;

  bool dispatchEvent(_EventJs event) native;

  bool hasAttributes() native;

  bool hasChildNodes() native;

  _NodeJs insertBefore(_NodeJs newChild, _NodeJs refChild) native;

  bool isDefaultNamespace(String namespaceURI) native;

  bool isEqualNode(_NodeJs other) native;

  bool isSameNode(_NodeJs other) native;

  bool isSupported(String feature, String version) native;

  String lookupNamespaceURI(String prefix) native;

  String lookupPrefix(String namespaceURI) native;

  void normalize() native;

  _NodeJs removeChild(_NodeJs oldChild) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  _NodeJs replaceChild(_NodeJs newChild, _NodeJs oldChild) native;
}
