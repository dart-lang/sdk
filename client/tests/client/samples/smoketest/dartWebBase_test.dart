// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
#library('Smoketests_main');

#import('benchmarklib.dart');
#import('dart:html');
#import('../../../../../lib/unittest/unittest.dart');
#import('../../../../../lib/unittest/html_config.dart');

void main() {
  useHtmlConfiguration();

  asyncTest('performanceTesting', 1, () { 
    window.setTimeout(BENCHMARK_SUITE.runBenchmarks, 0);
    window.setTimeout(testForCompletion, 0);
  });
}

testForCompletion() {
  Element element = document.query('#testResultScore');
  RegExp re = new RegExp('Score: [0-9]+');
  print(element.text);
  Expect.isTrue(re.hasMatch(element.text));
  callbackDone();
}
