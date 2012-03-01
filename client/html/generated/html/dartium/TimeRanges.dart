
class _TimeRangesImpl extends _DOMTypeBase implements TimeRanges {
  _TimeRangesImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  num end(int index) {
    return _wrap(_ptr.end(_unwrap(index)));
  }

  num start(int index) {
    return _wrap(_ptr.start(_unwrap(index)));
  }
}
