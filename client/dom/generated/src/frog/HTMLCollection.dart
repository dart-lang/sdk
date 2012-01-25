
class HTMLCollectionJs extends DOMTypeJs implements HTMLCollection native "*HTMLCollection" {

  int get length() native "return this.length;";

  NodeJs operator[](int index) native;

  void operator[]=(int index, NodeJs value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  NodeJs item(int index) native;

  NodeJs namedItem(String name) native;
}
