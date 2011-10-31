
class HTMLCollection native "HTMLCollection" {

  int length;

  Node operator[](int index) native;

  Node item(int index) native;

  Node namedItem(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
