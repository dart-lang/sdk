
class PerformanceJS implements Performance native "*Performance" {

  MemoryInfoJS get memory() native "return this.memory;";

  PerformanceNavigationJS get navigation() native "return this.navigation;";

  PerformanceTimingJS get timing() native "return this.timing;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
