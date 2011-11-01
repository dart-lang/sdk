
class XMLSerializer native "XMLSerializer" {

  String serializeToString(Node node) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
