
class _Uint8ClampedArrayImpl extends _Uint8ArrayImpl implements Uint8ClampedArray, List<int> {
  _Uint8ClampedArrayImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  Uint8ClampedArray subarray(int start, [int end = null]) {
    if (end === null) {
      return _wrap(_ptr.subarray(_unwrap(start)));
    } else {
      return _wrap(_ptr.subarray(_unwrap(start), _unwrap(end)));
    }
  }
}
