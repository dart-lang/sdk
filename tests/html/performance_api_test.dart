library PerformanceApiTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

  group('supported', () {
    test('supported', () {
      expect(Performance.supported, true);
    });
  });

  group('performance', () {
    test('PerformanceApi', () {
      // Check that code below will not throw exceptions if supported.
      var expectation = Performance.supported ? returnsNormally : throws;
      expect(() {
        var requestStart = window.performance.timing.requestStart;
        var responseStart = window.performance.timing.responseStart;
        var responseEnd = window.performance.timing.responseEnd;

        var loading = window.performance.timing.domLoading;
        var loadedStart = window.performance.timing.domContentLoadedEventStart;
        var loadedEnd = window.performance.timing.domContentLoadedEventEnd;
        var complete = window.performance.timing.domComplete;

        var loadEventStart = window.performance.timing.loadEventStart;
      }, expectation);
    });
  });
}
