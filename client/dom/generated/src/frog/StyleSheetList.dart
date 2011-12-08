
class StyleSheetList native "*StyleSheetList" {

  int length;

  StyleSheet operator[](int index) native;

  void operator[]=(int index, StyleSheet value) {
    throw new UnsupportedOperationException("Cannot assign element of immutable List.");
  }

  StyleSheet item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
