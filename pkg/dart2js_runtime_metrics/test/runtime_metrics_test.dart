// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// dart2jsOptions=--experimental-track-allocations

import 'package:dart2js_runtime_metrics/runtime_metrics.dart';
import 'package:expect/expect.dart';

void main() {
  Map metrics = runtimeMetrics;

  String expectedRuntime;
  if (1.0 is! int) {
    expectedRuntime = 'unknown';
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
    Expect.isTrue(metrics.containsKey('allocations'));
    dynamic allocations = metrics['allocations'];
    // We assume dart:_rti:Rti is always instantiated in the dart2js runtime.
    Expect.isTrue(allocations.containsKey('dart:_rti:Rti'));
    return;
  }

  if (expectedRuntime == 'dartdevc') {
    return;
  }

  if (expectedRuntime == 'unknown') {
    return;
  }

  throw 'Should not get here.';
}

class ClassWithLongName {}
