// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for http://dartbug.com/7964

library first_regression_test;

import 'dart:async';
import 'package:unittest/unittest.dart';

class DoubleTransformer<T> implements StreamTransformer<T, T> {
  Stream<T> bind(Stream<T> stream) {
    var transformer = new StreamTransformer<T, T>.fromHandlers(
        handleData: (T data, EventSink<T> sink) {
      sink.add(data);
      sink.add(data);
    });
    return transformer.bind(stream);
  }
}

main() {
  test("Double event before first", () {
    // This should not crash. Did crash by trying to complete future more
    // than once.
    new Stream.fromIterable([1, 2])
        .transform(new DoubleTransformer())
        .first
        .then(expectAsync((e) {}));
  });
}
