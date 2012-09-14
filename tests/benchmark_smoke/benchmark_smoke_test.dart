// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#library('benchmark_smoke_test');

// Tests that benchmark classes used in perf testing are not broken.
#import('benchmark_lib.dart');
#import('dart:html');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');

void main() {
  useHtmlConfiguration();

  test('performanceTesting', () {
    window.setTimeout(BENCHMARK_SUITE.runBenchmarks, 0);
    window.setTimeout(expectAsync0(testForCompletion), 0);
  });
}

testForCompletion() {
  Element element = document.query('#testResultScore');
  RegExp re = new RegExp('Score: [0-9]+');
  print(element.text);
  Expect.isTrue(re.hasMatch(element.text));
}
