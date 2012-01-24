
class WebKitBlobBuilderJS implements WebKitBlobBuilder native "*WebKitBlobBuilder" {

  void append(var arrayBuffer_OR_blob_OR_value, [String endings = null]) native;

  BlobJS getBlob([String contentType = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
