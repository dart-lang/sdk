// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";

import 'package:expect/async_helper.dart';
import "package:expect/expect.dart";

void main() async {
  asyncStart();
  var futures = [for (var i = 0; i < 5; i++) Future<int>.value(i)];
  var errors = [
    for (var i = 0; i < 5; i++)
      Future<int>.error("error $i", StackTrace.fromString("stack $i"))..ignore()
  ];

  // Empty list.
  Expect.listEquals([], await <Future<int>>[].wait);

  // Single future.
  Expect.listEquals([0], await <Future<int>>[futures[0]].wait);

  // Multiple future.
  Expect.listEquals([0, 1, 2, 3, 4], await futures.wait);

  // Single error.
  try {
    await [futures[0], futures[1], errors[2], futures[3], futures[4]].wait;
    Expect.fail("Didn't throw");
  } on ParallelWaitError<List<int?>, List<AsyncError?>> catch (e) {
    Expect.equals(0, e.values[0]);
    Expect.equals(1, e.values[1]);
    Expect.isNull(e.values[2]);
    Expect.equals(3, e.values[3]);
    Expect.equals(4, e.values[4]);

    Expect.isNull(e.errors[0]);
    Expect.isNull(e.errors[1]);
    Expect.equals("error 2", e.errors[2]?.error);
    Expect.isNull(e.errors[3]);
    Expect.isNull(e.errors[4]);

    var toString = e.toString();
    Expect.contains("ParallelWaitError:", toString);
    Expect.contains("error 2", toString);
    Expect.equals("stack 2", e.stackTrace.toString());
  }

  // Multiple errors.
  try {
    await [futures[0], errors[1], futures[2], errors[3], futures[4]].wait;
    Expect.fail("Didn't throw");
  } on ParallelWaitError<List<int?>, List<AsyncError?>> catch (e) {
    Expect.equals(0, e.values[0]);
    Expect.isNull(e.values[1]);
    Expect.equals(2, e.values[2]);
    Expect.isNull(e.values[3]);
    Expect.equals(4, e.values[4]);

    Expect.isNull(e.errors[0]);
    Expect.equals("error 1", e.errors[1]?.error);
    Expect.isNull(e.errors[2]);
    Expect.equals("error 3", e.errors[3]?.error);
    Expect.isNull(e.errors[4]);

    var toString = e.toString();
    Expect.contains("ParallelWaitError(2 errors):", toString);
    Expect.containsAny(["error 1", "error 3"], toString);
    Expect.containsAny(["stack 1", "stack 3"], e.stackTrace.toString());
  }

  // All errors.
  try {
    await errors.wait;
    Expect.fail("Didn't throw");
  } on ParallelWaitError<List<int?>, List<AsyncError?>> catch (e) {
    Expect.isNull(e.values[0]);
    Expect.isNull(e.values[1]);
    Expect.isNull(e.values[2]);
    Expect.isNull(e.values[3]);
    Expect.isNull(e.values[4]);

    Expect.equals("error 0", e.errors[0]?.error);
    Expect.equals("error 1", e.errors[1]?.error);
    Expect.equals("error 2", e.errors[2]?.error);
    Expect.equals("error 3", e.errors[3]?.error);
    Expect.equals("error 4", e.errors[4]?.error);

    var toString = e.toString();
    Expect.contains("ParallelWaitError(5 errors):", toString);
    Expect.containsAny(
        ["error 0", "error 1", "error 2", "error 3", "error 4"], toString);
    Expect.containsAny(["stack 0", "stack 1", "stack 2", "stack 3", "stack 4"],
        e.stackTrace.toString());
  }

  // Direct tests of `ParallelWaitError`.

  Expect.equals("ParallelWaitError",
      ParallelWaitError<Null, Null>(null, null, errorCount: null).toString());
  Expect.equals("ParallelWaitError",
      ParallelWaitError<Null, Null>(null, null, errorCount: 0).toString());
  Expect.equals("ParallelWaitError",
      ParallelWaitError<Null, Null>(null, null, errorCount: 1).toString());
  Expect.equals("ParallelWaitError(2 errors)",
      ParallelWaitError<Null, Null>(null, null, errorCount: 2).toString());
  Expect.equals("ParallelWaitError(9999 errors)",
      ParallelWaitError<Null, Null>(null, null, errorCount: 9999).toString());

  var defaultError = AsyncError(
      StateError("default error"), StackTrace.fromString("default stack"));
  final ParallelWaitError unthrownWithoutDefault =
      ParallelWaitError<Null, Null>(null, null);
  final ParallelWaitError unthrownWithDefault =
      ParallelWaitError<Null, Null>(null, null, defaultError: defaultError);
  final ParallelWaitError thrownWithoutDefault;
  final StackTrace thrownWithoutDefaultStack;
  try {
    throw ParallelWaitError<Null, Null>(null, null);
  } catch (e, s) {
    thrownWithoutDefault = e as ParallelWaitError;
    thrownWithoutDefaultStack = s;
  }
  final ParallelWaitError thrownWithDefault;
  try {
    throw ParallelWaitError<Null, Null>(null, null, defaultError: defaultError);
  } catch (e) {
    thrownWithDefault = e as ParallelWaitError;
  }

  Expect.equals("ParallelWaitError", thrownWithoutDefault.toString());
  Expect.equals("ParallelWaitError", unthrownWithoutDefault.toString());
  Expect.equals(
      "ParallelWaitError: ${defaultError.error}", thrownWithDefault.toString());
  Expect.equals("ParallelWaitError: ${defaultError.error}",
      unthrownWithDefault.toString());

  Expect.identical(unthrownWithDefault.stackTrace, defaultError.stackTrace);
  Expect.identical(thrownWithDefault.stackTrace, defaultError.stackTrace);
  Expect.equals(thrownWithoutDefault.stackTrace.toString(),
      thrownWithoutDefaultStack.toString());
  Expect.isNull(unthrownWithoutDefault.stackTrace);

  // Both default and count.
  Expect.equals(
      "ParallelWaitError(25 errors): ${defaultError.error}",
      ParallelWaitError<Null, Null>(null, null,
              errorCount: 25, defaultError: defaultError)
          .toString());
  asyncEnd();
}
