// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that the `Error.stackTrace` is set when thrown, not before,
// and that it contains the same stack trace text as the stack trace
// captured by `catch` the first time the error is thrown,
// and that it doesn't change if thrown again.
// (Derived from `runtime/tests/vm/dart/error_stacktrace_test.dart`.)

import "package:expect/async_helper.dart";
import "package:expect/expect.dart";

void main() async {
  testSync();
  testSyncStar(); // A `throw` in a `sync*` function.

  asyncStart();
  await testAsync();
  await testAsyncStar();
  asyncEnd();
}

void testSync() {
  Never throwError(Error error) => throw error;
  Never throwWithStack(Error error, StackTrace stack) =>
      Error.throwWithStackTrace(error, stack);
  dynamic throwNSM(dynamic c) => c * 4;

  _testSync("sync", throwError, throwWithStack, throwNSM);
}

void testSyncStar() {
  Iterable<Never> throwErrorStream(Error error) sync* {
    yield throw error;
  }

  Iterable<Never> throwWithStackStream(Error error, StackTrace stack) sync* {
    yield Error.throwWithStackTrace(error, stack);
  }

  Iterable<dynamic> throwNSMStream(dynamic c) sync* {
    yield c * 4;
  }

  Never throwError(Error error) => throwErrorStream(error).first;
  Never throwWithStack(Error error, StackTrace stack) =>
      throwWithStackStream(error, stack).first;
  dynamic throwNSM(dynamic c) => throwNSMStream(c).first;

  _testSync("sync*", throwError, throwWithStack, throwNSM);
}

Future<void> testAsync() async {
  Future<Never> throwError(Error error) async => throw error;
  Future<Never> throwErrorWithStack(Error error, StackTrace stack) async =>
      Error.throwWithStackTrace(error, stack);
  Future<dynamic> throwNSM(dynamic c) async => c * 4;

  return _testAsync("async", throwError, throwErrorWithStack, throwNSM);
}

Future<void> testAsyncStar() async {
  Stream<Never> throwErrorStream(Error error) async* {
    yield throw error;
  }

  Future<Never> throwError(Error error) => throwErrorStream(error).first;

  Stream<Never> throwErrorWithStackStream(
    Error error,
    StackTrace stack,
  ) async* {
    yield Error.throwWithStackTrace(error, stack);
  }

  Future<Never> throwErrorWithStack(Error error, StackTrace stack) =>
      throwErrorWithStackStream(error, stack).first;

  Stream<dynamic> throwNSMStream(dynamic c) async* {
    yield c * 4;
  }

  Future<dynamic> throwNSM(dynamic c) => throwNSMStream(c).first;

  return _testAsync("async*", throwError, throwErrorWithStack, throwNSM);
}

void _testSync(
  String functionKind,
  Never Function(Error) throwError,
  Never Function(Error, StackTrace) throwWithStack,
  dynamic Function(dynamic) throwNSM,
) {
  // Checks that an error first thrown with [firstStack] as [Error.stackTrace],
  // will keep that stack trace if thrown again asynchronously.
  void testErrorSet(String throwKind, Error error, StackTrace firstStack) {
    var desc = "$functionKind $throwKind";
    // Was thrown with [stackTrace] as stack trace.
    Expect.isNotNull(error.stackTrace, "$desc throw - did not set .stackTrace");
    Expect.stringEquals(
      firstStack.toString(),
      error.stackTrace.toString(),
      "$desc, caught stack/set stack - not same",
    );
    // Throw same error again, using `throw`, with different stack.
    try {
      throwError(error);
    } on Error catch (e, s) {
      var redesc = "$functionKind throw again";
      Expect.identical(error, e, "$redesc - not same error");
      Expect.notEquals(
        firstStack.toString(),
        s.toString(),
        "$redesc, set stack/new stack - not different",
      );
      // Did not overwrite existing `error.stackTrace`.
      Expect.equals(
        firstStack.toString(),
        e.stackTrace.toString(),
        "$redesc - changed .stackTrace",
      );
    }

    // Throw same error again using `Error.throwWithStackTrace`.
    var stack2 = StackTrace.fromString("stack test string 2");
    try {
      throwWithStack(error, stack2);
    } on Error catch (e, s) {
      var redesc = "$functionKind E.tWST again";
      Expect.identical(error, e, "$redesc - not same error");
      Expect.equals(
        stack2.toString(),
        s.toString(),
        "$redesc, thrown stack/caught stack - not same",
      );
      Expect.notEquals(
        firstStack.toString(),
        s.toString(),
        "$redesc, first stack/new stack - not different",
      );
      // Did not overwrite existing `error.stackTrace`.
      Expect.equals(
        firstStack.toString(),
        e.stackTrace.toString(),
        "$redesc - changed .stackTrace",
      );
    }
  }

  {
    // System thrown error.
    try {
      throwNSM(NoMult());
      Expect.fail("Did not throw");
    } on NoSuchMethodError catch (e, s) {
      testErrorSet("throwNSM", e, s);
    }
  }

  {
    // User thrown error, explicit `throw`.
    var error = StateError("error test string");
    Expect.isNull(error.stackTrace);
    try {
      throwError(error);
    } on Error catch (e, s) {
      Expect.identical(
        error,
        e,
        "$functionKind throw: thrown error/caught error - not same",
      );
      testErrorSet("throw", e, s);
    }
  }

  {
    // Thrown using `Error.throwWithStackTrace`.
    var error = StateError("error test string");
    Expect.isNull(error.stackTrace);
    var stack = StackTrace.fromString("stack test string");
    try {
      throwWithStack(error, stack);
    } on Error catch (e, s) {
      Expect.identical(
        error,
        e,
        "$functionKind E.tWST: thrown error/caught error - not same",
      );
      Expect.stringEquals(
        stack.toString(),
        s.toString(),
        "$functionKind E.tWST: thrown stack/caught stack - not same",
      );
      testErrorSet("E.tWST", e, s);
    }
  }
}

Future<void> _testAsync(
  String functionKind,
  Future<Never> Function(Error) throwError,
  Future<Never> Function(Error, StackTrace) throwWithStack,
  Future<dynamic> Function(dynamic) throwNSM,
) async {
  // Checks that an error first thrown with [firstStack] as [Error.stackTrace],
  // will keep that stack trace if thrown again asynchronously.
  Future<void> testErrorSet(
    String throwKind,
    Error error,
    StackTrace firstStack,
  ) async {
    var desc = "$functionKind $throwKind";
    // Was thrown with [stackTrace] as stack trace.
    Expect.isNotNull(error.stackTrace, "$desc throw - did not set .stackTrace");
    Expect.stringEquals(
      firstStack.toString(),
      error.stackTrace.toString(),
      "$desc, caught stack/set stack - not same",
    );
    // Throw same error again, using `throw`, with different stack.
    try {
      await throwError(error);
    } on Error catch (e, s) {
      var redesc = "$functionKind throw again";
      Expect.identical(error, e, "$redesc - not same error");
      if (functionKind != "async*") {
        // An async* throw happens asynchronously, so its stack trace
        // can be just the same short stack from the event loop every time.
        Expect.notEquals(
          firstStack.toString(),
          s.toString(),
          "$redesc, set stack/new stack - not different",
        );
      }
      // Did not overwrite existing `error.stackTrace`.
      Expect.equals(
        firstStack.toString(),
        e.stackTrace.toString(),
        "$redesc - changed .stackTrace",
      );
    }

    // Throw same error again using `Error.throwWithStackTrace`.
    var stack2 = StackTrace.fromString("stack test string 2");
    try {
      await throwWithStack(error, stack2);
    } on Error catch (e, s) {
      var redesc = "$functionKind E.tWST again";
      Expect.identical(error, e, "$redesc - not same error");
      Expect.equals(
        stack2.toString(),
        s.toString(),
        "$redesc, thrown stack/caught stack - not same",
      );
      if (functionKind != "async*") {
        Expect.notEquals(
          firstStack.toString(),
          s.toString(),
          "$redesc, first stack/new stack - not different",
        );
      }
      // Did not overwrite existing `error.stackTrace`.
      Expect.equals(
        firstStack.toString(),
        e.stackTrace.toString(),
        "$redesc - changed .stackTrace",
      );
    }
  }

  asyncStart();

  {
    // System thrown error.
    try {
      await throwNSM(NoMult());
      Expect.fail("Did not throw");
    } on NoSuchMethodError catch (e, s) {
      await testErrorSet("throwNSM", e, s);
    }
  }

  {
    // User thrown error, explicit `throw`.
    var error = StateError("error test string");
    Expect.isNull(error.stackTrace);
    try {
      await throwError(error);
    } on Error catch (e, s) {
      Expect.identical(
        error,
        e,
        "$functionKind throw: thrown error/caught error - not same",
      );
      await testErrorSet("throw", e, s);
    }
  }

  {
    // Thrown using `Error.throwWithStackTrace`.
    var error = StateError("error test string");
    Expect.isNull(error.stackTrace);
    var stack = StackTrace.fromString("stack test string");
    try {
      await throwWithStack(error, stack);
    } on Error catch (e, s) {
      Expect.identical(
        error,
        e,
        "$functionKind E.tWST: thrown error/caught error - not same",
      );
      Expect.stringEquals(
        stack.toString(),
        s.toString(),
        "$functionKind E.tWST: thrown stack/caught stack - not same",
      );
      await testErrorSet("E.tWST", e, s);
    }
  }
  asyncEnd();
}

// Has no `operator *`, forcing a dynamic `NoSuchMethodError`
// when used in `c * 4`.
class NoMult {}
