// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

/// Regression test for https://github.com/dart-lang/sdk/issues/64079.
///
/// Getter invocations where the getter return type is a generic type argument
/// instantiated as a callable interface should be invoked using the `.call()`
/// method.

class Callable {
  String call() => 'result';
}

class Box<T> {
  T field;
  Box(this.field);
  T get getter => field;
}

void main() {
  final list = [Callable()];
  Expect.equals('result', list.first());

  final box = Box(Callable());
  Expect.equals('result', box.field());
  Expect.equals('result', box.getter());
}
