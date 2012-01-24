
class XMLSerializerJS implements XMLSerializer native "*XMLSerializer" {

  String serializeToString(NodeJS node) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
