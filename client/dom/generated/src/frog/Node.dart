
class Node native "*Node" {

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

  NamedNodeMap attributes;

  String baseURI;

  NodeList childNodes;

  Node firstChild;

  Node lastChild;

  String localName;

  String namespaceURI;

  Node nextSibling;

  String nodeName;

  int nodeType;

  String nodeValue;

  Document ownerDocument;

  Element parentElement;

  Node parentNode;

  String prefix;

  Node previousSibling;

  String textContent;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  Node appendChild(Node newChild) native;

  Node cloneNode(bool deep) native;

  int compareDocumentPosition(Node other) native;

  bool contains(Node other) native;

  bool dispatchEvent(Event event) native;

  bool hasAttributes() native;

  bool hasChildNodes() native;

  Node insertBefore(Node newChild, Node refChild) native;

  bool isDefaultNamespace(String namespaceURI) native;

  bool isEqualNode(Node other) native;

  bool isSameNode(Node other) native;

  bool isSupported(String feature, String version) native;

  String lookupNamespaceURI(String prefix) native;

  String lookupPrefix(String namespaceURI) native;

  void normalize() native;

  Node removeChild(Node oldChild) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  Node replaceChild(Node newChild, Node oldChild) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
