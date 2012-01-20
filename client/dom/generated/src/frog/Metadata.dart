
class Metadata native "*Metadata" {

  Date get modificationTime() native "return this.modificationTime;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
