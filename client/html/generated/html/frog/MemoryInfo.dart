
class _MemoryInfoImpl implements MemoryInfo native "*MemoryInfo" {

  final int jsHeapSizeLimit;

  final int totalJSHeapSize;

  final int usedJSHeapSize;
}
