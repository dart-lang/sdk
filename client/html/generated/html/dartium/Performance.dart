
class _PerformanceImpl extends _DOMTypeBase implements Performance {
  _PerformanceImpl._wrap(ptr) : super._wrap(ptr);

  MemoryInfo get memory() => _wrap(_ptr.memory);

  PerformanceNavigation get navigation() => _wrap(_ptr.navigation);

  PerformanceTiming get timing() => _wrap(_ptr.timing);
}
