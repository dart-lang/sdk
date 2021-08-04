// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart2js_runtime_metrics/startup_metrics.dart';
import 'package:expect/expect.dart';

void main() {
  Map<String, Object> metrics = startupMetrics;

  print('metrics: $metrics');

  String expectedRuntime;
  if (1.0 is! int) {
    expectedRuntime = 'vm';
  } else if (ClassWithLongName().toString().contains('minified:')) {
    // dart2js minified: "Instance of 'minified:xy'".
    expectedRuntime = 'dart2js';
  } else if ('$main' == "Closure 'main'") {
    // dart2js non-minified.
    expectedRuntime = 'dart2js';
  } else if ('$main'.startsWith('Closure: () => void from: function main()')) {
    expectedRuntime = 'dartdevc';
  } else {
    throw 'Cannot feature-test current runtime:'
        '\nmetrics = $metrics\n main = $main';
  }

  Expect.isTrue(metrics.containsKey('runtime'), "Has 'runtime' key: $metrics");
  Expect.equals(expectedRuntime, metrics['runtime'],
      "Expected 'runtime: $expectedRuntime': $metrics");

  if (expectedRuntime == 'dart2js') {
    Expect.isTrue(metrics.containsKey('callMainMs'));
    return;
  }

  if (expectedRuntime == 'dartdevc') {
    Expect.equals(1, metrics.length);
    return;
  }

  if (expectedRuntime == 'vm') {
    Expect.equals(1, metrics.length);
    return;
  }

  throw 'Should not get here.';
}

class ClassWithLongName {}
