
class _BlobImpl extends _DOMTypeBase implements Blob {
  _BlobImpl._wrap(ptr) : super._wrap(ptr);

  int get size() => _wrap(_ptr.size);

  String get type() => _wrap(_ptr.type);

  Blob webkitSlice([int start = null, int end = null, String contentType = null]) {
    if (start === null) {
      if (end === null) {
        if (contentType === null) {
          return _wrap(_ptr.webkitSlice());
        }
      }
    } else {
      if (end === null) {
        if (contentType === null) {
          return _wrap(_ptr.webkitSlice(_unwrap(start)));
        }
      } else {
        if (contentType === null) {
          return _wrap(_ptr.webkitSlice(_unwrap(start), _unwrap(end)));
        } else {
          return _wrap(_ptr.webkitSlice(_unwrap(start), _unwrap(end), _unwrap(contentType)));
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
}
