
class NodeList native "*NodeList" {

  int length;

  Node operator[](int index) native;

  Node item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
