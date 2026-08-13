// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/81068.
// Verifies that TFA doesn't crash when handling a class which
// implements Future and another generic class and a cast to FutureOr.

import 'dart:async';

class A<T> {}

class B<T> extends A<String> implements Future<T> {
  noSuchMethod(Invocation i) => throw 'Not implemented';
}

B createB<T>() => B<T>();

void main() {
  print(createB<int>() as FutureOr<double>);
}
