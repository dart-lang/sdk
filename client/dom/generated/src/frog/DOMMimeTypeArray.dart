
class DOMMimeTypeArray native "*DOMMimeTypeArray" {

  int get length() native "return this.length;";

  DOMMimeType item(int index) native;

  DOMMimeType namedItem(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
