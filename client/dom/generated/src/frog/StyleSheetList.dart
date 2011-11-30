
class StyleSheetList native "*StyleSheetList" {

  int length;

  StyleSheet operator[](int index) native;

  StyleSheet item(int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
