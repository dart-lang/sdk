
class _FileReaderSyncImpl extends _DOMTypeBase implements FileReaderSync {
  _FileReaderSyncImpl._wrap(ptr) : super._wrap(ptr);

  ArrayBuffer readAsArrayBuffer(Blob blob) {
    return _wrap(_ptr.readAsArrayBuffer(_unwrap(blob)));
  }

  String readAsBinaryString(Blob blob) {
    return _wrap(_ptr.readAsBinaryString(_unwrap(blob)));
  }

  String readAsDataURL(Blob blob) {
    return _wrap(_ptr.readAsDataURL(_unwrap(blob)));
  }

  String readAsText(Blob blob, [String encoding = null]) {
    if (encoding === null) {
      return _wrap(_ptr.readAsText(_unwrap(blob)));
    } else {
      return _wrap(_ptr.readAsText(_unwrap(blob), _unwrap(encoding)));
    }
  }
}
