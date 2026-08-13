// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/46319.

import 'dart:async';

void main() {}

Future<T> fn<T>() {
  // DDC was crashing during compilation when trying to tag the following
  // function expression with a type.
  return hn(() => gn());
}

S gn<S>() {
  throw 'in gn';
}

Future<R> hn<R>(FutureOr<R> Function() foo) {
  throw 'in hn';
}
