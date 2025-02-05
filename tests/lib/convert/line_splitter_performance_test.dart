// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library line_splitter_test;

import 'dart:convert';

import "package:expect/expect.dart";

void main() {
  testEfficiency();
}

/// Regression test for https://dartbug.com/51167
///
/// Had quadratic time behavior when concatenating chunks without linebreaks.
///
/// Should now only use linear time/space for buffering.
void testEfficiency() {
  // After fix: finishes in < 1 second on desktop.
  // Before fix, with N = 100000, took 25 seconds.
  const N = 1000000;
  String result = ""; // Starts empty, set once.
  var sink = LineSplitter()
      .startChunkedConversion(ChunkedConversionSink.withCallback((lines) {
    // Gets called only once with exactly one line.
    Expect.equals("", result);
    Expect.equals(1, lines.length);
    var line = lines.first;
    Expect.notEquals("", line);
    result = line;
  }));
  for (var i = 0; i < N; i++) {
    sink.add("xy");
  }
  sink.close();
  Expect.equals("xy" * N, result);
}
