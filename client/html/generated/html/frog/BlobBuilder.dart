
class _BlobBuilderImpl implements BlobBuilder native "*WebKitBlobBuilder" {

  void append(var arrayBuffer_OR_blob_OR_value, [String endings = null]) native;

  _BlobImpl getBlob([String contentType = null]) native;
}
