
class _PerformanceJs extends _DOMTypeJs implements Performance native "*Performance" {

  _MemoryInfoJs get memory() native "return this.memory;";

  _PerformanceNavigationJs get navigation() native "return this.navigation;";

  _PerformanceTimingJs get timing() native "return this.timing;";
}
