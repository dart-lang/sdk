
class DOMPluginArrayJs extends DOMTypeJs implements DOMPluginArray native "*DOMPluginArray" {

  int get length() native "return this.length;";

  DOMPluginJs item(int index) native;

  DOMPluginJs namedItem(String name) native;

  void refresh(bool reload) native;
}
