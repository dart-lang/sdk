
class _PerformanceTimingImpl extends _DOMTypeBase implements PerformanceTiming {
  _PerformanceTimingImpl._wrap(ptr) : super._wrap(ptr);

  int get connectEnd() => _wrap(_ptr.connectEnd);

  int get connectStart() => _wrap(_ptr.connectStart);

  int get domComplete() => _wrap(_ptr.domComplete);

  int get domContentLoadedEventEnd() => _wrap(_ptr.domContentLoadedEventEnd);

  int get domContentLoadedEventStart() => _wrap(_ptr.domContentLoadedEventStart);

  int get domInteractive() => _wrap(_ptr.domInteractive);

  int get domLoading() => _wrap(_ptr.domLoading);

  int get domainLookupEnd() => _wrap(_ptr.domainLookupEnd);

  int get domainLookupStart() => _wrap(_ptr.domainLookupStart);

  int get fetchStart() => _wrap(_ptr.fetchStart);

  int get loadEventEnd() => _wrap(_ptr.loadEventEnd);

  int get loadEventStart() => _wrap(_ptr.loadEventStart);

  int get navigationStart() => _wrap(_ptr.navigationStart);

  int get redirectEnd() => _wrap(_ptr.redirectEnd);

  int get redirectStart() => _wrap(_ptr.redirectStart);

  int get requestStart() => _wrap(_ptr.requestStart);

  int get responseEnd() => _wrap(_ptr.responseEnd);

  int get responseStart() => _wrap(_ptr.responseStart);

  int get secureConnectionStart() => _wrap(_ptr.secureConnectionStart);

  int get unloadEventEnd() => _wrap(_ptr.unloadEventEnd);

  int get unloadEventStart() => _wrap(_ptr.unloadEventStart);
}
