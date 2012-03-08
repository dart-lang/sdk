
class _DOMURLImpl extends _DOMTypeBase implements DOMURL {
  _DOMURLImpl._wrap(ptr) : super._wrap(ptr);

  String createObjectURL(var blob_OR_stream) {
    if (blob_OR_stream is MediaStream) {
      return _wrap(_ptr.createObjectURL(_unwrap(blob_OR_stream)));
    } else {
      if (blob_OR_stream is Blob) {
        return _wrap(_ptr.createObjectURL(_unwrap(blob_OR_stream)));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void revokeObjectURL(String url) {
    _ptr.revokeObjectURL(_unwrap(url));
    return;
  }
}
