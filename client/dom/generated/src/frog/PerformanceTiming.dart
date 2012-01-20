
class PerformanceTiming native "*PerformanceTiming" {

  int get connectEnd() native "return this.connectEnd;";

  int get connectStart() native "return this.connectStart;";

  int get domComplete() native "return this.domComplete;";

  int get domContentLoadedEventEnd() native "return this.domContentLoadedEventEnd;";

  int get domContentLoadedEventStart() native "return this.domContentLoadedEventStart;";

  int get domInteractive() native "return this.domInteractive;";

  int get domLoading() native "return this.domLoading;";

  int get domainLookupEnd() native "return this.domainLookupEnd;";

  int get domainLookupStart() native "return this.domainLookupStart;";

  int get fetchStart() native "return this.fetchStart;";

  int get loadEventEnd() native "return this.loadEventEnd;";

  int get loadEventStart() native "return this.loadEventStart;";

  int get navigationStart() native "return this.navigationStart;";

  int get redirectEnd() native "return this.redirectEnd;";

  int get redirectStart() native "return this.redirectStart;";

  int get requestStart() native "return this.requestStart;";

  int get responseEnd() native "return this.responseEnd;";

  int get responseStart() native "return this.responseStart;";

  int get secureConnectionStart() native "return this.secureConnectionStart;";

  int get unloadEventEnd() native "return this.unloadEventEnd;";

  int get unloadEventStart() native "return this.unloadEventStart;";

  var dartObjectLocalStorage;

  String get typeName() native;
}
