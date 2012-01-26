
class DOMMimeTypeArrayJs extends DOMTypeJs implements DOMMimeTypeArray native "*DOMMimeTypeArray" {

  int get length() native "return this.length;";

  DOMMimeTypeJs item(int index) native;

  DOMMimeTypeJs namedItem(String name) native;
}
