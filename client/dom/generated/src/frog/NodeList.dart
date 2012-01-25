
class NodeListJs extends DOMTypeJs implements NodeList native "*NodeList" {

  int get length() native "return this.length;";

  NodeJs operator[](int index) native;

  void operator[]=(int index, NodeJs value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  NodeJs item(int index) native;
}
