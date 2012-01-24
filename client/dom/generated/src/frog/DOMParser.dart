
class DOMParserJS implements DOMParser native "*DOMParser" {

  DocumentJS parseFromString(String str, String contentType) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
