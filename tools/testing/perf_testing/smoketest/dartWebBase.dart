// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('benchmarklib.dart');

#import('dart:html');

void main() {
  window.on.contentLoaded.add((Event e) => BENCHMARK_SUITE.runBenchmarks());
}
