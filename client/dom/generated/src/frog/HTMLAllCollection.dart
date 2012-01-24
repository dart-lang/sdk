
class HTMLAllCollectionJS implements HTMLAllCollection native "*HTMLAllCollection" {

  int get length() native "return this.length;";

  NodeJS item(int index) native;

  NodeJS namedItem(String name) native;

  NodeListJS tags(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
