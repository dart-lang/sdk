
class _DOMPluginArrayImpl implements DOMPluginArray native "*DOMPluginArray" {

  final int length;

  _DOMPluginImpl item(int index) native;

  _DOMPluginImpl namedItem(String name) native;

  void refresh(bool reload) native;
}
