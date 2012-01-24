
class DOMPluginArrayJS implements DOMPluginArray native "*DOMPluginArray" {

  int get length() native "return this.length;";

  DOMPluginJS item(int index) native;

  DOMPluginJS namedItem(String name) native;

  void refresh(bool reload) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
