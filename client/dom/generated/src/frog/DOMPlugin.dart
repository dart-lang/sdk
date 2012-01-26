
class DOMPluginJs extends DOMTypeJs implements DOMPlugin native "*DOMPlugin" {

  String get description() native "return this.description;";

  String get filename() native "return this.filename;";

  int get length() native "return this.length;";

  String get name() native "return this.name;";

  DOMMimeTypeJs item(int index) native;

  DOMMimeTypeJs namedItem(String name) native;
}
