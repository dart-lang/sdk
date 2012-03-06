
class _Uint8ClampedArrayImpl extends _Uint8ArrayImpl implements Uint8ClampedArray, List<int> {
  _Uint8ClampedArrayImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  void setElements(Object array, [int offset = null]) {
    if (offset === null) {
      _ptr.setElements(_unwrap(array));
      return;
    } else {
      _ptr.setElements(_unwrap(array), _unwrap(offset));
      return;
    }
  }

  Uint8ClampedArray subarray(int start, [int end = null]) {
    if (end === null) {
      return _wrap(_ptr.subarray(_unwrap(start)));
    } else {
      return _wrap(_ptr.subarray(_unwrap(start), _unwrap(end)));
    }
  }
}
