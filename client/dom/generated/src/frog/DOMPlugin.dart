
class DOMPlugin native "*DOMPlugin" {

  String description;

  String filename;

  int length;

  String name;

  DOMMimeType item(int index) native;

  DOMMimeType namedItem(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
