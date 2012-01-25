
class NamedNodeMapJs extends DOMTypeJs implements NamedNodeMap native "*NamedNodeMap" {

  int get length() native "return this.length;";

  NodeJs operator[](int index) native;

  void operator[]=(int index, NodeJs value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  NodeJs getNamedItem(String name) native;

  NodeJs getNamedItemNS(String namespaceURI, String localName) native;

  NodeJs item(int index) native;

  NodeJs removeNamedItem(String name) native;

  NodeJs removeNamedItemNS(String namespaceURI, String localName) native;

  NodeJs setNamedItem(NodeJs node) native;

  NodeJs setNamedItemNS(NodeJs node) native;
}
