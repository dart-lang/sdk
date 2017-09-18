// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:test/test.dart";

main() {
  test("stream iterator basic", () async {
    var stream = createStream();
    StreamIterator iterator = new StreamIterator(stream);
    expect(iterator.current, isNull);
    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current, 42);
    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current, 37);
    expect(await iterator.moveNext(), isFalse);
    expect(iterator.current, isNull);
    expect(await iterator.moveNext(), isFalse);
  });

  test("stream iterator prefilled", () async {
    Stream stream = createStream();
    StreamIterator iterator = new StreamIterator(stream);
    await new Future.delayed(Duration.ZERO);
    expect(iterator.current, isNull);
    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current, 42);
    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current, 37);
    expect(await iterator.moveNext(), isFalse);
    expect(iterator.current, isNull);
    expect(await iterator.moveNext(), isFalse);
  });

  test("stream iterator error", () async {
    Stream stream = createErrorStream();
    StreamIterator iterator = new StreamIterator(stream);
    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current, 42);
    var hasNext = iterator.moveNext();
    expect(hasNext, throwsA("BAD")); // This is an async expectation,
    await hasNext.catchError((_) {}); // so we have to wait for the future too.
    expect(iterator.current, isNull);
    expect(await iterator.moveNext(), isFalse);
    expect(iterator.current, isNull);
  });

  test("stream iterator current/moveNext during move", () async {
    Stream stream = createStream();
    StreamIterator iterator = new StreamIterator(stream);
    var hasNext = iterator.moveNext();
    expect(iterator.moveNext, throwsA(isStateError));
    expect(await hasNext, isTrue);
    expect(iterator.current, 42);
    iterator.cancel();
  });

  test("stream iterator error during cancel", () async {
    Stream stream = createCancelErrorStream();
    StreamIterator iterator = new StreamIterator(stream);
    for (int i = 0; i < 10; i++) {
      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current, i);
    }
    var hasNext = iterator.moveNext(); // active moveNext will be completed.
    var cancel = iterator.cancel();
    expect(cancel, throwsA("BAD"));
    expect(await hasNext, isFalse);
    expect(await iterator.moveNext(), isFalse);
  });
}

Stream createStream() async* {
  yield 42;
  yield 37;
}

Stream createErrorStream() async* {
  yield 42;
  // Emit an error without stopping the generator.
  yield* (new Future.error("BAD").asStream());
  yield 37;
}

/// Create a stream that throws when cancelled.
Stream createCancelErrorStream() async* {
  int i = 0;
  try {
    while (true) yield i++;
  } finally {
    throw "BAD";
  }
}
