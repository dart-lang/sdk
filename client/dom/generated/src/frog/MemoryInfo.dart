
class MemoryInfo native "*MemoryInfo" {

  int get jsHeapSizeLimit() native "return this.jsHeapSizeLimit;";

  int get totalJSHeapSize() native "return this.totalJSHeapSize;";

  int get usedJSHeapSize() native "return this.usedJSHeapSize;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
