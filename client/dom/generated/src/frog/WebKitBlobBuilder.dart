
class WebKitBlobBuilderJs extends DOMTypeJs implements WebKitBlobBuilder native "*WebKitBlobBuilder" {

  void append(var arrayBuffer_OR_blob_OR_value, [String endings = null]) native;

  BlobJs getBlob([String contentType = null]) native;
}
