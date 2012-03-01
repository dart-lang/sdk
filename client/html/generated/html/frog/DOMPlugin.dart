
class _DOMPluginImpl implements DOMPlugin native "*DOMPlugin" {

  final String description;

  final String filename;

  final int length;

  final String name;

  _DOMMimeTypeImpl item(int index) native;

  _DOMMimeTypeImpl namedItem(String name) native;
}
