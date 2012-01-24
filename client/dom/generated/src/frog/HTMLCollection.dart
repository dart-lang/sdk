
class HTMLCollectionJS implements HTMLCollection native "*HTMLCollection" {

  int get length() native "return this.length;";

  NodeJS operator[](int index) native;

  void operator[]=(int index, NodeJS value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  NodeJS item(int index) native;

  NodeJS namedItem(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
