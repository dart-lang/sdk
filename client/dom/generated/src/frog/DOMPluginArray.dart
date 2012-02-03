
class _DOMPluginArrayJs extends _DOMTypeJs implements DOMPluginArray native "*DOMPluginArray" {

  int get length() native "return this.length;";

  _DOMPluginJs item(int index) native;

  _DOMPluginJs namedItem(String name) native;

  void refresh(bool reload) native;
}
