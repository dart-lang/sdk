
class DOMMimeType native "*DOMMimeType" {

  String get description() native "return this.description;";

  DOMPlugin get enabledPlugin() native "return this.enabledPlugin;";

  String get suffixes() native "return this.suffixes;";

  String get type() native "return this.type;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
