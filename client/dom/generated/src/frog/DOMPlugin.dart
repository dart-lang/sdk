
class _DOMPluginJs extends _DOMTypeJs implements DOMPlugin native "*DOMPlugin" {

  String get description() native "return this.description;";

  String get filename() native "return this.filename;";

  int get length() native "return this.length;";

  String get name() native "return this.name;";

  _DOMMimeTypeJs item(int index) native;

  _DOMMimeTypeJs namedItem(String name) native;
}
