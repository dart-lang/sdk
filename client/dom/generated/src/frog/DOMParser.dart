
class DOMParser native "*DOMParser" {

  Document parseFromString(String str, String contentType) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
