
class _ArrayBufferImpl extends _DOMTypeBase implements ArrayBuffer {
  _ArrayBufferImpl._wrap(ptr) : super._wrap(ptr);

  int get byteLength() => _wrap(_ptr.byteLength);

  ArrayBuffer slice(int begin, [int end = null]) {
    if (end === null) {
      return _wrap(_ptr.slice(_unwrap(begin)));
    } else {
      return _wrap(_ptr.slice(_unwrap(begin), _unwrap(end)));
    }
  }
}
