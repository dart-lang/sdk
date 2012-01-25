
class StyleSheetListJs extends DOMTypeJs implements StyleSheetList native "*StyleSheetList" {

  int get length() native "return this.length;";

  StyleSheetJs operator[](int index) native;

  void operator[]=(int index, StyleSheetJs value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  StyleSheetJs item(int index) native;
}
