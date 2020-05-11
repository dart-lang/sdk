// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:expect/minitest.dart';

main() {
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
