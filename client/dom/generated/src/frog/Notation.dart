
class NotationJS extends NodeJS implements Notation native "*Notation" {

  String get publicId() native "return this.publicId;";

  String get systemId() native "return this.systemId;";
}
