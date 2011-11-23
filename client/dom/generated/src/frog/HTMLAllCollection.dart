
class HTMLAllCollection native "*HTMLAllCollection" {

  int length;

  Node item(int index) native;

  Node namedItem(String name) native;

  NodeList tags(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
