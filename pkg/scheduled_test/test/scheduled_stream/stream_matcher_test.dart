// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library scheduled_test.stream_matcher_test;

import 'dart:async';

import 'package:scheduled_test/scheduled_stream.dart';
import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/src/utils.dart';

import 'package:metatest/metatest.dart';
import '../utils.dart';

/// Returns a [ScheduledStream] that asynchronously emits the numbers 1 through
/// 5 and then closes.
ScheduledStream createStream() {
  var controller = new StreamController();
  var stream = new ScheduledStream(controller.stream);

  var future = pumpEventQueue();
  for (var i = 1; i <= 5; i++) {
    future = future.then((_) {
      controller.add(i);
      return pumpEventQueue();
    });
  }
  future.then((_) => controller.close());

  return stream;
}

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  setUpTimeout();

  expectTestPasses("expect() with matching values passes", () {
    var stream = createStream();
    stream.expect(1);
    stream.expect(2);
    stream.expect(3);
    stream.expect(4);
    stream.expect(5);
  });

  expectTestFails("expect() with a non-matching value fails", () {
    var stream = createStream();
    stream.expect(1);
    stream.expect(2);
    stream.expect(100);
  }, (errors) {
    expect(errors, hasLength(1));
    expect(errors.first.error.message, equals(
        "Expected: <100>\n"
        " Emitted: * 1\n"
        "          * 2\n"
        "          * 3"));
  });

  expectTestFails("expect() with too few values fails", () {
    var stream = createStream();
    stream.expect(1);
    stream.expect(2);
    stream.expect(3);
    stream.expect(4);
    stream.expect(5);
    stream.expect(6);
  }, (errors) {
    expect(errors, hasLength(1));
    expect(errors.first.error.message, equals(
        "Expected: <6>\n"
        " Emitted: * 1\n"
        "          * 2\n"
        "          * 3\n"
        "          * 4\n"
        "          * 5\n"
        "   Which: unexpected end of stream"));
  });

  expectTestPasses("expect() with matching matcher passes", () {
    var stream = createStream();
    stream.expect(greaterThan(0));
    stream.expect(greaterThan(1));
    stream.expect(greaterThan(2));
    stream.expect(greaterThan(3));
    stream.expect(greaterThan(4));
  });

  expectTestFails("expect() with a non-matching matcher fails", () {
    var stream = createStream();
    stream.expect(greaterThan(0));
    stream.expect(greaterThan(1));
    stream.expect(greaterThan(100));
  }, (errors) {
    expect(errors, hasLength(1));
    expect(errors.first.error.message, equals(
        "Expected: a value greater than <100>\n"
        " Emitted: * 1\n"
        "          * 2\n"
        "          * 3\n"
        "   Which: is not a value greater than <100>"));
  });

  expectTestPasses("nextValues() with matching values succeeds", () {
    createStream().expect(nextValues(3, unorderedEquals([3, 2, 1])));
  });

  expectTestFails("nextValues() without enough values fails", () {
    createStream().expect(nextValues(6, unorderedEquals([3, 2, 1])));
  }, (errors) {
    expect(errors, hasLength(1));
    expect(errors.first.error.message, equals(
        "Expected: 6 values that equals [3, 2, 1] unordered\n"
        " Emitted: * 1\n"
        "          * 2\n"
        "          * 3\n"
        "          * 4\n"
        "          * 5\n"
        "   Which: unexpected end of stream"));
  });

  expectTestFails("nextValues() with non-matching values fails", () {
    createStream().expect(nextValues(3, unorderedEquals([2, 3, 4])));
  }, (errors) {
    expect(errors, hasLength(1));
    expect(errors.first.error.message, equals(
        "Expected: 3 values that equals [2, 3, 4] unordered\n"
        " Emitted: * 1\n"
        "          * 2\n"
        "          * 3\n"
        "   Which: has no match for <4> at index 2"));
  });

  expectTestPasses("inOrder() with several values matches and consumes those "
      "values", () {
    var stream = createStream();
    stream.expect(inOrder([1, 2, 3, 4]));
    stream.expect(5);
  });

  expectTestPasses("inOrder() with several stream matchers matches them", () {
    createStream().expect(inOrder([
      consumeThrough(3),
      nextValues(2, unorderedEquals([5, 4]))
    ]));
  });

  expectTestPasses("inOrder() with no values succeeds and consumes nothing",
      () {
    var stream = createStream();
    stream.expect(inOrder([]));
    stream.expect(1);
  });

  expectTestFails("inOrder() fails if a sub-matcher fails", () {
    createStream().expect(inOrder([
      nextValues(3, unorderedEquals([2, 3, 4])),
      consumeThrough(5)
    ]));
  }, (errors) {
    expect(errors, hasLength(1));
    expect(errors.first.error.message, equals(
        "Expected: * 3 values that equals [2, 3, 4] unordered\n"
        "        | * values followed by <5>\n"
        " Emitted: * 1\n"
        "          * 2\n"
        "          * 3\n"
        "   Which: matcher #1 failed:\n"
        "        | has no match for <4> at index 2"));
  });

  expectTestFails("inOrder() with one value has a simpler description", () {
    createStream().expect(inOrder([100]));
  }, (errors) {
    expect(errors, hasLength(1));
    expect(errors.first.error.message, equals(
        "Expected: <100>\n"
        " Emitted: * 1"));
  });

  expectTestPasses("consumeThrough() consumes values through the given matcher",
      () {
    var stream = createStream();
    stream.expect(consumeThrough(inOrder([2, 3])));
    stream.expect(4);
  });

  expectTestPasses("consumeThrough() will stop if the first value matches", () {
    var stream = createStream();
    stream.expect(consumeThrough(inOrder([1, 2])));
    stream.expect(3);
  });

  expectTestFails("consumeThrough() will fail if the stream ends before the "
      "value is reached", () {
    createStream().expect(consumeThrough(inOrder([5, 6])));
  }, (errors) {
    expect(errors, hasLength(1));
    expect(errors.first.error.message, equals(
        "Expected: values followed by:\n"
        "        |   * <5>\n"
        "        |   * <6>\n"
        " Emitted: * 1\n"
        "          * 2\n"
        "          * 3\n"
        "          * 4\n"
        "          * 5\n"
        "   Which: unexpected end of stream"));
  });

  expectTestPasses("consumeWhile() consumes values while the given matcher "
      "matches", () {
    var stream = createStream();
    stream.expect(consumeWhile(lessThan(4)));
    stream.expect(4);
  });

  expectTestPasses("consumeWhile() consumes values in chunks", () {
    var stream = createStream();
    stream.expect(consumeWhile(inOrder([anything, anything])));
    stream.expect(5);
  });

  expectTestPasses("consumeWhile() will stop if the first value doesn't match",
      () {
    var stream = createStream();
    stream.expect(consumeWhile(inOrder([2, 3])));
    stream.expect(1);
  });

  expectTestPasses("either() will match if the first branch matches", () {
    createStream().expect(either(1, 100));
  });

  expectTestPasses("either() will match if the second branch matches", () {
    createStream().expect(either(100, 1));
  });

  expectTestPasses("either() will consume the maximal number of values if both "
      "branches match", () {
    // First branch consumes more.
    var stream = createStream();
    stream.expect(either(inOrder([1, 2, 3]), 1));
    stream.expect(4);

    // Second branch consumes more.
    stream = createStream();
    stream.expect(either(1, inOrder([1, 2, 3])));
    stream.expect(4);
  });

  expectTestFails("either() will fail if neither branch matches", () {
    createStream().expect(either(
        inOrder([3, 2, 1]),
        nextValues(4, unorderedEquals([5, 4, 3, 2]))));
  }, (errors) {
    expect(errors, hasLength(1));
    expect(errors.first.error.message, equals(
        "Expected: either\n"
        "        |   * <3>\n"
        "        |   * <2>\n"
        "        |   * <1>\n"
        "        | or\n"
        "        |   4 values that equals [5, 4, 3, 2] unordered\n"
        " Emitted: * 1\n"
        "          * 2\n"
        "          * 3\n"
        "          * 4\n"
        "   Which: both\n"
        "        |   matcher #1 failed\n"
        "        | and\n"
        "        |   has no match for <5> at index 0"));
  });

  expectTestPasses("allow() consumes the matcher if it matches", () {
    var stream = createStream();
    stream.expect(allow(inOrder([1, 2, 3])));
    stream.expect(4);
  });

  expectTestPasses("allow() consumes nothing if the matcher doesn't match", () {
    var stream = createStream();
    stream.expect(allow(inOrder([1, 2, 100])));
    stream.expect(1);
  });

  expectTestPasses("never() consumes everything if the matcher never matches",
      () {
    var stream = createStream();
    stream.expect(never(inOrder([2, 1])));
  });

  expectTestFails("never() fails if the matcher matches", () {
    var stream = createStream();
    stream.expect(never(inOrder([2, 3])));
  }, (errors) {
    expect(errors, hasLength(1));
    expect(errors.first.error.message, equals(
        "Expected: never\n"
        "        |   * <2>\n"
        "        |   * <3>\n"
        " Emitted: * 1\n"
        "          * 2\n"
        "          * 3\n"
        "   Which: matched\n"
        "        |   * <2>\n"
        "        |   * <3>"));
  });

  expectTestPasses("isDone succeeds at the end of the stream", () {
    var stream = createStream();
    stream.expect(consumeThrough(5));
    stream.expect(isDone);
  });

  expectTestFails("isDone fails before the end of the stream", () {
    var stream = createStream();
    stream.expect(consumeThrough(4));
    stream.expect(isDone);
  }, (errors) {
    expect(errors, hasLength(1));
    expect(errors.first.error.message, equals(
        "Expected: is done\n"
        " Emitted: * 1\n"
        "          * 2\n"
        "          * 3\n"
        "          * 4\n"
        "          * 5\n"
        "   Which: stream wasn't finished"));
  });
}
