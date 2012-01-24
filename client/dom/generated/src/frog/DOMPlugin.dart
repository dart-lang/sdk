
class DOMPluginJS implements DOMPlugin native "*DOMPlugin" {

  String get description() native "return this.description;";

  String get filename() native "return this.filename;";

  int get length() native "return this.length;";

  String get name() native "return this.name;";

  DOMMimeTypeJS item(int index) native;

  DOMMimeTypeJS namedItem(String name) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
