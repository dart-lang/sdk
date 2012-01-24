
class DOMMimeTypeArrayJS implements DOMMimeTypeArray native "*DOMMimeTypeArray" {

  int get length() native "return this.length;";

  DOMMimeTypeJS item(int index) native;

  DOMMimeTypeJS namedItem(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
