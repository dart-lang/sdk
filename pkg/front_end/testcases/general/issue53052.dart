// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

FutureOr<Iterable<int>> f() sync* {
  yield 'Hello!' as dynamic;
}

FutureOr<Stream<int>> g() async* {
  yield* 'Hello!' as dynamic;
}

main() async {
  var iterable = f();
  if (iterable is Future<Object?>) return;
  expectThrows(() { int i = iterable.first; });

  var stream = g();
  if (stream is Future<Object?>) return;
  await expectAsyncThrows(() async { int i = await stream.first; });
}

expectThrows(f) {
  bool hasThrown = true;
  try {
    f();
    hasThrown = false;
  } catch(e) {}
  if (!hasThrown) {
    throw "Expected the function to throw.";
  }
}

expectAsyncThrows(f) async {
  bool hasThrown = true;
  try {
    await f();
    hasThrown = false;
  } catch(e) {}
  if (!hasThrown) {
    throw "Expected the function to throw.";
  }
}
