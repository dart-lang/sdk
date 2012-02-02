
class _DOMMimeTypeArrayJs extends _DOMTypeJs implements DOMMimeTypeArray native "*DOMMimeTypeArray" {

  int get length() native "return this.length;";

  _DOMMimeTypeJs item(int index) native;

  _DOMMimeTypeJs namedItem(String name) native;
}
