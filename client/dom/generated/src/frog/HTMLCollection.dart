
class HTMLCollection native "HTMLCollection" {

  int length;

  Node operator[](int index) native;

  void operator[]=(int index, Node value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  Node item(int index) native;

  Node namedItem(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
