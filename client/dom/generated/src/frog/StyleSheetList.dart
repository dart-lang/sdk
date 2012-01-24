
class StyleSheetListJS implements StyleSheetList native "*StyleSheetList" {

  int get length() native "return this.length;";

  StyleSheetJS operator[](int index) native;

  void operator[]=(int index, StyleSheetJS value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  StyleSheetJS item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
