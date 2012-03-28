#library('PerformanceApiTest');
#import('../../../../lib/unittest/unittest_dom.dart');
#import('dart:dom');

main() {
  forLayoutTests();
  test('PerformanceApi', () {
    // Check that code below will not throw exceptions.
    var requestStart = window.performance.timing.requestStart;
    var responseStart = window.performance.timing.responseStart;
    var responseEnd = window.performance.timing.responseEnd;
    
    var loading = window.performance.timing.domLoading;
    var loadedStart = window.performance.timing.domContentLoadedEventStart;
    var loadedEnd = window.performance.timing.domContentLoadedEventEnd;
    var complete = window.performance.timing.domComplete;

    var loadEventStart = window.performance.timing.loadEventStart;
  });
}
