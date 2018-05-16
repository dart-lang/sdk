// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Exact regression test for issue #33040.

import 'dart:async';

class Optional<T> {}

typedef T ConvertFunction<T>();

T blockingLatest<T>() {
  return null;
}

abstract class ObservableModel<T> {}

abstract class AsyncValueMixin<T> {
  Future<T> get asyncValue {
    ConvertFunction<T> f = blockingLatest;
    if (f is! ConvertFunction<T>) throw "error";
    return null;
  }
}

abstract class OptionalSettableObservableModel<T>
    extends ObservableModel<Optional<T>> with AsyncValueMixin<Optional<T>> {}

class FooObservableModel extends OptionalSettableObservableModel<int> {}

Future<void> main() async {
  var model = new FooObservableModel();
  await model.asyncValue;
}
