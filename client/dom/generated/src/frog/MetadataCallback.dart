
class MetadataCallback native "MetadataCallback" {

  bool handleEvent(Metadata metadata) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
