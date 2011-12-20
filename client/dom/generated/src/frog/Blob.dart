
class Blob native "*Blob" {

  int size;

  String type;

  Blob webkitSlice([int start = null, int end = null, String contentType = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
