
class Entity extends Node native "*Entity" {

  String get notationName() native "return this.notationName;";

  String get publicId() native "return this.publicId;";

  String get systemId() native "return this.systemId;";
}
