
class MemoryInfoJs extends DOMTypeJs implements MemoryInfo native "*MemoryInfo" {

  int get jsHeapSizeLimit() native "return this.jsHeapSizeLimit;";

  int get totalJSHeapSize() native "return this.totalJSHeapSize;";

  int get usedJSHeapSize() native "return this.usedJSHeapSize;";
}
