
class SVGStringList native "*SVGStringList" {

  int numberOfItems;

  String appendItem(String item) native;

  void clear() native;

  String getItem(int index) native;

  String initialize(String item) native;

  String insertItemBefore(String item, int index) native;

  String removeItem(int index) native;

  String replaceItem(String item, int index) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
