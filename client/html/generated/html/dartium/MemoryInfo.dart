
class _MemoryInfoImpl extends _DOMTypeBase implements MemoryInfo {
  _MemoryInfoImpl._wrap(ptr) : super._wrap(ptr);

  int get jsHeapSizeLimit() => _wrap(_ptr.jsHeapSizeLimit);

  int get totalJSHeapSize() => _wrap(_ptr.totalJSHeapSize);

  int get usedJSHeapSize() => _wrap(_ptr.usedJSHeapSize);
}
