// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/7964

library first_regression_test;
import 'dart:async';
import '../../../pkg/unittest/lib/unittest.dart';

class DoubleTransformer<T> extends StreamEventTransformer<T, T> {
  void handleData(T data, EventSink<T> sink) {
    sink.add(data);
    sink.add(data);
  }
}

main() {
  test("Double event before first", () {
    // This should not crash. Did crash by trying to complete future more
    // than once.
    new Stream.fromIterable([1, 2])
        .transform(new DoubleTransformer())
        .first
        .then(expectAsync1((e) {}));
  });
}
