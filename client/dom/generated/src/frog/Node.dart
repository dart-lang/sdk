
class Node native "Node" {

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
