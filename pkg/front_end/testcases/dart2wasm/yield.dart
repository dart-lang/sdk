// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Iterable<int> method(Iterable<int> iterable) sync* {
  yield 1;
  yield 2;
  yield* iterable;
}

Stream<int> asyncMethod(Stream<int> stream) async* {
  yield 1;
  yield 2;
  yield* stream;
}
