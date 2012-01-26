
class PerformanceJs extends DOMTypeJs implements Performance native "*Performance" {

  MemoryInfoJs get memory() native "return this.memory;";

  PerformanceNavigationJs get navigation() native "return this.navigation;";

  PerformanceTimingJs get timing() native "return this.timing;";
}
