
class _WebKitBlobBuilderJs extends _DOMTypeJs implements WebKitBlobBuilder native "*WebKitBlobBuilder" {

  void append(var arrayBuffer_OR_blob_OR_value, [String endings = null]) native;

  _BlobJs getBlob([String contentType = null]) native;
}
