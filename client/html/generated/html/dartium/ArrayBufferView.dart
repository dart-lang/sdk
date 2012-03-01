
class _ArrayBufferViewImpl extends _DOMTypeBase implements ArrayBufferView {
  _ArrayBufferViewImpl._wrap(ptr) : super._wrap(ptr);

  ArrayBuffer get buffer() => _wrap(_ptr.buffer);

  int get byteLength() => _wrap(_ptr.byteLength);

  int get byteOffset() => _wrap(_ptr.byteOffset);
}
