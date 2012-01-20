
class Performance native "*Performance" {

  MemoryInfo get memory() native "return this.memory;";

  PerformanceNavigation get navigation() native "return this.navigation;";

  PerformanceTiming get timing() native "return this.timing;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
