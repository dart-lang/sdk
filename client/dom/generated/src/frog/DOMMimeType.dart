
class DOMMimeTypeJs extends DOMTypeJs implements DOMMimeType native "*DOMMimeType" {

  String get description() native "return this.description;";

  DOMPluginJs get enabledPlugin() native "return this.enabledPlugin;";

  String get suffixes() native "return this.suffixes;";

  String get type() native "return this.type;";
}
