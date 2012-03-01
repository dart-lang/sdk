
class _PerformanceNavigationImpl extends _DOMTypeBase implements PerformanceNavigation {
  _PerformanceNavigationImpl._wrap(ptr) : super._wrap(ptr);

  int get redirectCount() => _wrap(_ptr.redirectCount);

  int get type() => _wrap(_ptr.type);
}
