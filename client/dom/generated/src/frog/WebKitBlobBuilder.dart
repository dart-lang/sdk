
class WebKitBlobBuilder native "*WebKitBlobBuilder" {

  void append(var blob_OR_value, [String endings = null]) native;

  Blob getBlob([String contentType = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
