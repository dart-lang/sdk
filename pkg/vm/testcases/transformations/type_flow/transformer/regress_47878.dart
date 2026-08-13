// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/47878

abstract class Disposable {}

class A {}

class Data<T> {
  T? value;
}

class DataStream<T> {
  DataStream({newValue, Data<T>? stream}) {
    var lastValue = stream!.value;

    if (lastValue != null &&
        lastValue is Disposable &&
        lastValue != newValue) {}
  }
}

void main() {
  DataStream<A>();
}
