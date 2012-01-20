
class DOMPluginArray native "*DOMPluginArray" {

  int get length() native "return this.length;";

  DOMPlugin item(int index) native;

  DOMPlugin namedItem(String name) native;

  void refresh(bool reload) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
