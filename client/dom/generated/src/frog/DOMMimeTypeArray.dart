
class DOMMimeTypeArray native "*DOMMimeTypeArray" {

  int length;

  DOMMimeType item(int index) native;

  DOMMimeType namedItem(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
