
class NamedNodeMap native "*NamedNodeMap" {

  int length;

  Node operator[](int index) native;

  void operator[]=(int index, Node value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  Node getNamedItem(String name) native;

  Node getNamedItemNS(String namespaceURI, String localName) native;

  Node item(int index) native;

  Node removeNamedItem(String name) native;

  Node removeNamedItemNS(String namespaceURI, String localName) native;

  Node setNamedItem(Node node) native;

  Node setNamedItemNS(Node node) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
