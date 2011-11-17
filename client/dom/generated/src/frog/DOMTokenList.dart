
class DOMTokenList native "DOMTokenList" {

  int length;

  void add(String token) native;

  bool contains(String token) native;

  String item(int index) native;

  void remove(String token) native;

  String toString() native;

  bool toggle(String token) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
