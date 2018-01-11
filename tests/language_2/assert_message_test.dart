// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

// TODO(rnystrom): Unify with assert_with_message_test.dart.

main() {
  // Only run with asserts enabled mode.
  bool assertsEnabled = false;
  assert(assertsEnabled = true);
  if (!assertsEnabled) return;

  // Basics.
  assert(true, "");

  int x = null;
  // Successful asserts won't execute message.
  assert(true, x + 42);
  assert(true, throw "unreachable");

  // Can use any value as message.
  try {
    assert(false, 42);
  } on AssertionError catch (e) {
    Expect.equals(42, e.message);
  }

  try {
    assert(false, "");
  } on AssertionError catch (e) {
    Expect.equals("", e.message);
  }

  try {
    assert(false, null);
  } on AssertionError catch (e) {
    Expect.equals(null, e.message);
  }

  // Test expression can throw.
  try {
    assert(throw "test", throw "message");
  } on String catch (e) {
    Expect.equals("test", e);
  }

  // Message expression can throw.
  try {
    assert(false, throw "message");
  } on String catch (e) {
    Expect.equals("message", e);
  }

  // Failing asserts evaluate message after test.
  var list = [];
  try {
    assert((list..add(1)).isEmpty, (list..add(3)).length);
  } on AssertionError catch (e) {
    Expect.equals(2, e.message);
    Expect.listEquals([1, 3], list);
  }

  asyncStart();
  asyncTests().then((_) {
    asyncEnd();
  });
}

Future asyncTests() async {
  // You can await in both condition and message.
  assert(true, await 0);
  assert(await true, 1);
  assert(await true, await 2);

  // Successful asserts won't await/evaluate message.
  void unreachable() => throw "unreachable";
  assert(await true, await unreachable());

  try {
    assert(false, await 3);
  } on AssertionError catch (e) {
    Expect.equals(3, e.message);
  }

  var falseFuture = new Future.value(false);
  var numFuture = new Future.value(4);

  try {
    assert(await falseFuture, await numFuture);
  } on AssertionError catch (e) {
    Expect.equals(4, e.message);
  }

  try {
    assert(await falseFuture, await new Future.error("error"));
  } on String catch (e) {
    Expect.equals("error", e);
  }
}
