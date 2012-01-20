
class HTMLAllCollection native "*HTMLAllCollection" {

  int get length() native "return this.length;";

  Node item(int index) native;

  Node namedItem(String name) native;

  NodeList tags(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
