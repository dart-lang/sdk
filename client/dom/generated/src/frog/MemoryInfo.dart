
class MemoryInfo native "MemoryInfo" {

  int jsHeapSizeLimit;

  int totalJSHeapSize;

  int usedJSHeapSize;

  var dartObjectLocalStorage;

  String get typeName() native;
}
