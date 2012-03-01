
class _BlobBuilderImpl extends _DOMTypeBase implements BlobBuilder {
  _BlobBuilderImpl._wrap(ptr) : super._wrap(ptr);

  void append(var arrayBuffer_OR_blob_OR_value, [String endings = null]) {
    if (arrayBuffer_OR_blob_OR_value is Blob) {
      if (endings === null) {
        _ptr.append(_unwrap(arrayBuffer_OR_blob_OR_value));
        return;
      }
    } else {
      if (arrayBuffer_OR_blob_OR_value is ArrayBuffer) {
        if (endings === null) {
          _ptr.append(_unwrap(arrayBuffer_OR_blob_OR_value));
          return;
        }
      } else {
        if (arrayBuffer_OR_blob_OR_value is String) {
          if (endings === null) {
            _ptr.append(_unwrap(arrayBuffer_OR_blob_OR_value));
            return;
          } else {
            _ptr.append(_unwrap(arrayBuffer_OR_blob_OR_value), _unwrap(endings));
            return;
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  Blob getBlob([String contentType = null]) {
    if (contentType === null) {
      return _wrap(_ptr.getBlob());
    } else {
      return _wrap(_ptr.getBlob(_unwrap(contentType)));
    }
  }
}
