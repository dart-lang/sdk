
class Notation extends Node native "*Notation" {

  String get publicId() native "return this.publicId;";

  String get systemId() native "return this.systemId;";
}
