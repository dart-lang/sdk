// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:async";
import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

// Test of Error.throwWithStackTrace.

main() {
  // Ensure `systemStack` is different from any other stack tracek.
  var systemStack = (() => StackTrace.current)();

  // Test that an error can be thrown with a system stack trace..
  {
    var error = ArgumentError("e1");
    try {
      Error.throwWithStackTrace(error, systemStack);
      Expect.fail("Didn't throw: e1.1");
    } on Error catch (e, s) {
      Expect.identical(error, e, "e1.2");
      // No not expect *identical* stack trace objects.
      Expect.equals("$systemStack", "$s", "e1.3");
      Expect.isNotNull(error.stackTrace, "e1.4");
      Expect.equals("$systemStack", "${error.stackTrace}", "e1.5");
    }
  }

  // Test that an error can be thrown with a user-created stack trace..
  {
    var stringStack = StackTrace.fromString("Nonce");
    var error = ArgumentError("e2");
    try {
      Error.throwWithStackTrace(error, stringStack);
      Expect.fail("Didn't throw: e2.1");
    } on Error catch (e, s) {
      Expect.identical(error, e, "e2.2");
      // No not expect *identical* stack trace objects.
      Expect.equals("$stringStack", "$s", "e2.3");
      Expect.isNotNull(error.stackTrace, "e2.4");
      Expect.equals("$stringStack", "${error.stackTrace}", "e2.5");
    }
  }

  // Test that a non-error object can be thrown too.
  {
    var exception = FormatException("e3");
    try {
      Error.throwWithStackTrace(exception, systemStack);
      Expect.fail("Didn't throw: e3.1");
    } on Exception catch (e, s) {
      Expect.identical(exception, e, "e3.2");
      // No not expect *identical* stack trace objects.
      Expect.equals("$systemStack", "$s", "e3.3");
    }
  }

  // Test that an [Error] not extending {Error} can be thrown,
  // but doesn't (and cannot) set the stack trace.
  {
    var error = CustomError("e4");
    try {
      Error.throwWithStackTrace(error, systemStack);
      Expect.fail("Didn't throw: e4.1");
    } on Error catch (e, s) {
      Expect.identical(error, e, "e4.2");
      // No not expect *identical* stack trace objects.
      Expect.equals("$systemStack", "$s", "e4.3");
      Expect.isNull(error.stackTrace, "e4.4");
    }
  }

  // Test that an already set stack trace isn't changed.
  {
    var error = ArgumentError("e5");
    StackTrace? originalStack;
    try {
      throw error;
    } on Error catch (e) {
      originalStack = e.stackTrace;
    }
    Expect.isNotNull(originalStack);
    Expect.notIdentical(originalStack, systemStack);
    Expect.notEquals("$originalStack", "");
    try {
      Error.throwWithStackTrace(error, systemStack);
      Expect.fail("Didn't throw: e5.1");
    } on Error catch (e, s) {
      Expect.identical(error, e, "e5.2");
      // No not expect *identical* stack trace objects.
      Expect.equals("$systemStack", "$s", "e5.3");
      // Expect the already-set stack trace to stay.
      Expect.isNotNull(error.stackTrace, "e5.4");
      Expect.equals("$originalStack", "${error.stackTrace}", "e5.5");
    }
  }

  // Works with OutOfMemoryError.
  {
    var error = const OutOfMemoryError();
    try {
      Error.throwWithStackTrace(error, systemStack);
    } on Error catch (e, s) {
      Expect.identical(error, e);
      Expect.equals("$systemStack", "$s");
    }
  }

  // Works with StackOverflowError.
  {
    var error = const StackOverflowError();
    try {
      Error.throwWithStackTrace(error, systemStack);
    } on Error catch (e, s) {
      Expect.identical(error, e);
      Expect.equals("$systemStack", "$s");
    }
  }

  // Also for live, captured, StackOverflowError.
  {
    Object error;
    Never foo() => foo() + 1;
    try {
      foo(); // Force stack overflow.
    } catch (e, s) {
      error = e;
    }
    // Some platforms might use another error than StackOverflowError.
    // Should work with whichever object gets here.
    try {
      Error.throwWithStackTrace(error, systemStack);
    } catch (e, s) {
      Expect.identical(error, e);
      Expect.equals("$systemStack", "$s");
    }
  }

  asyncTest(() async {
    var theFuture = Future.value(null);

    // Test that throwing inside an asynchronous context can be caught.
    {
      var error = ArgumentError("e6");
      try {
        await theFuture;
        Error.throwWithStackTrace(error, systemStack);
        Expect.fail("Didn't throw: e6.1");
        await theFuture;
      } on Error catch (e, s) {
        Expect.identical(error, e, "e6.2");
        // No not expect *identical* stack trace objects.
        Expect.equals("$systemStack", "$s", "e6.3");
        Expect.isNotNull(error.stackTrace, "e6.4");
        Expect.equals("$systemStack", "${error.stackTrace}", "e6.5");
      }
    }

    // Test that throwing in asynchronous context can be locally uncaught.
    {
      asyncStart();
      var error = ArgumentError("e7");
      var future = () async {
        await theFuture;
        Error.throwWithStackTrace(error, systemStack);
        Expect.fail("Didn't throw: e7.1");
        await theFuture;
        return null; // Force future type to Future<dynamic>
      }();
      future.catchError((e, s) {
        Expect.identical(error, e, "e7.2");
        // No not expect *identical* stack trace objects.
        Expect.equals("$systemStack", "$s", "e7.3");
        Expect.isNotNull(error.stackTrace, "e7.4");
        Expect.equals("$systemStack", "${error.stackTrace}", "e7.5");
        asyncEnd();
      });
    }

    // Test throwing an uncaught async error caught by the Zone.
    {
      asyncStart();
      var error = ArgumentError("e8");
      await runZonedGuarded(() {
        // Make an uncaught asynchronous error.
        (() async {
          await theFuture;
          Error.throwWithStackTrace(error, systemStack);
          Expect.fail("Didn't throw: e8.1");
          await theFuture;
        }());
      }, (e, s) {
        Expect.identical(error, e, "e8.2");
        // No not expect *identical* stack trace objects.
        Expect.equals("$systemStack", "$s", "e8.3");
        Expect.isNotNull(error.stackTrace, "e8.4");
        Expect.equals("$systemStack", "${error.stackTrace}", "e8.5");
        asyncEnd();
      });
    }
  });
}

class CustomError implements Error {
  final String message;
  CustomError(this.message);
  StackTrace? get stackTrace => null;
  String toString() => "CustomError: $message";
}
