
class NamedNodeMapJS implements NamedNodeMap native "*NamedNodeMap" {

  int get length() native "return this.length;";

  NodeJS operator[](int index) native;

  void operator[]=(int index, NodeJS value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  NodeJS getNamedItem(String name) native;

  NodeJS getNamedItemNS(String namespaceURI, String localName) native;

  NodeJS item(int index) native;

  NodeJS removeNamedItem(String name) native;

  NodeJS removeNamedItemNS(String namespaceURI, String localName) native;

  NodeJS setNamedItem(NodeJS node) native;

  NodeJS setNamedItemNS(NodeJS node) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
