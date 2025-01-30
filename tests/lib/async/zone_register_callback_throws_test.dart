// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';
import 'dart:async';

// Regression test for https://dartbug.com/59913
//
// The zone registration for `Timer` constructors was not as intended.
// - The constructor itself called `bind*CallbackGuarded`.
// - The root zone's `createTimer`/`createPeriodicTimer` did another
//   `zone.bind*Callback` on the already registered function,
//   but did not guard it, which is really the most important part.
// - If a zone intercepts a callback and makes it throw,
//   the latter `bind` would trigger first and the error would not
//   be caught, hitting the event loop in the root zone.
//
// After fixing this, the `Timer` constructors register the callback,
// and the root zone's `create*Timer` doesn't register the callback,
// but it does ensure that it runs in the correct zone, and that
// uncaught errors are reported in that zone.

void main() {
  asyncStart();
  int safeRun = 0;
  // Not touching binary callbacks, to avoid intercepting error handlers.
  void zoneTest(
    void Function() body, {
    bool wrapLast = false,
    void Function()? beforeCallback,
    void Function()? beforeRun,
    void Function(Object, StackTrace)? onError,
  }) {
    asyncStart();
    // Keep this completer outside of all zone handling.
    var testStack = StackTrace.current;
    bool firstRun = true;
    var zone = Zone.current.fork(
      specification: ZoneSpecification(
        registerCallback: <R>(self, parent, zone, f) {
          R callback() {
            beforeCallback?.call();
            return f();
          }

          if (!wrapLast) {
            // Parent registers wrapped function.
            return parent.registerCallback(zone, callback);
          } else {
            // Wrapped function wraps parent registration.
            f = parent.registerCallback(zone, f);
            return callback;
          }
        },
        registerUnaryCallback: <R, P>(self, parent, zone, f) {
          R callback(P v) {
            beforeCallback?.call();
            return f(v);
          }

          if (!wrapLast) {
            // Parent registers wrapped function.
            return parent.registerUnaryCallback(zone, callback);
          } else {
            // Wrapped function wraps parent registration.
            f = parent.registerUnaryCallback(zone, f);
            return callback;
          }
        },
        run: <R>(self, parent, zone, f) {
          // Don't intercept the initial `zone.run` of `body`.
          if (safeRun == 0) beforeRun?.call();
          return parent.run(zone, f);
        },
        runUnary: <R, P>(self, parent, zone, f, v1) {
          beforeRun?.call();
          return parent.runUnary(zone, f, v1);
        },
        handleUncaughtError: (self, parent, zone, error, stack) {
          stack = combineStacks(stack, testStack);
          if (onError != null) {
            onError(error, stack);
          } else {
            parent.handleUncaughtError(
              zone,
              error,
              combineStacks(StackTrace.current, stack),
            );
          }
        },
      ),
    );
    safeRun++;
    try {
      zone.run(body);
    } finally {
      safeRun--;
      asyncEnd();
    }
  }

  // Reusable error.
  Object error = AssertionError("RegisterThrows");

  // Timers and microtasks work.
  zoneTest(() {
    asyncStart();
    Timer(const Duration(milliseconds: 1), () {
      asyncEnd();
    });
  });

  zoneTest(() {
    asyncStart();
    Timer.periodic(const Duration(milliseconds: 1), (t) {
      if (t.tick > 1) {
        t.cancel();
        asyncEnd();
      }
    });
  });

  zoneTest(() {
    asyncStart();
    scheduleMicrotask(() {
      asyncEnd();
    });
  });

  // If the callback throws, it's caught in the zone.
  void Function(Object e, StackTrace s) expectError(Object expected) => (
    Object e,
    StackTrace s,
  ) {
    if (identical(expected, e)) {
      asyncEnd();
    } else {
      Error.throwWithStackTrace(e, combineStacks(StackTrace.current, s));
    }
  };

  zoneTest(() {
    asyncStart();
    Timer(const Duration(milliseconds: 1), () {
      throw error;
    });
  }, onError: expectError(error));

  zoneTest(() {
    asyncStart();
    Timer.periodic(const Duration(milliseconds: 1), (t) {
      if (t.tick > 1) {
        t.cancel();
        throw error;
      }
    });
  }, onError: expectError(error));

  zoneTest(() {
    asyncStart();
    scheduleMicrotask(() {
      throw error;
    });
  }, onError: expectError(error));

  void throwError() {
    throw error;
  }

  // If the registered function replacement throws,
  // the error is also caught in the zone's error handler.
  zoneTest(
    () {
      asyncStart();
      Timer(const Duration(milliseconds: 1), () {
        Expect.fail("Unreachable");
      });
    },
    beforeCallback: throwError,
    onError: expectError(error),
  );

  Timer? periodicTimer;
  zoneTest(
    () {
      asyncStart();
      periodicTimer = Timer.periodic(const Duration(milliseconds: 1), (t) {
        Expect.fail("Unreachable");
      });
    },
    beforeCallback: throwError,
    onError: (e, s) {
      periodicTimer!.cancel(); // Cancel the timer, otherwise it'll keep firing.
      expectError(error)(e, s);
    },
  );

  zoneTest(
    () {
      asyncStart();
      scheduleMicrotask(() {
        Expect.fail("Unreachable");
      });
    },
    beforeCallback: throwError,
    onError: expectError(error),
  );

  // Calling the zone functions directly does not register the function.
  zoneTest(() {
    asyncStart();
    Zone.current.createTimer(const Duration(milliseconds: 1), () {
      asyncEnd();
    });
  }, beforeCallback: throwError);

  zoneTest(() {
    asyncStart();
    Zone.current.createPeriodicTimer(const Duration(milliseconds: 1), (t) {
      if (t.tick > 1) {
        t.cancel();
        asyncEnd();
      }
    });
  }, beforeCallback: throwError);

  zoneTest(() {
    asyncStart();
    Zone.current.scheduleMicrotask(() {
      asyncEnd();
    });
  }, beforeCallback: throwError);

  // Nested zones work "as expected".

  var error2 = StateError("Outer zone error");

  // Outer `register*Callback` runs last, wraps (and here throws first).
  zoneTest(
    () {
      asyncStart(4);
      zoneTest(
        () {
          Timer(const Duration(milliseconds: 1), () {
            Expect.fail("Unreachable");
          });
        },
        beforeCallback: throwError,
        onError: expectError(error2),
      );
      Timer? periodicTimer;
      zoneTest(
        () {
          periodicTimer = Timer.periodic(const Duration(milliseconds: 1), (t) {
            Expect.fail("Unreachable");
          });
        },
        beforeCallback: throwError,
        onError: (e, s) {
          periodicTimer!.cancel();
          expectError(error2)(e, s);
        },
      );
      zoneTest(
        () {
          scheduleMicrotask(() {
            Expect.fail("Unreachable");
          });
        },
        beforeCallback: throwError,
        onError: expectError(error2),
      );
      asyncEnd();
    },
    beforeCallback: () {
      throw error2;
    },
  );

  // Inner `register*Callback` wrapped function runs first if it wants to.

  zoneTest(
    () {
      asyncStart(4);
      zoneTest(
        wrapLast: true,
        () {
          Timer(const Duration(milliseconds: 1), () {
            Expect.fail("Unreachable");
          });
        },
        beforeCallback: throwError,
        onError: expectError(error),
      );
      Timer? periodicTimer;
      zoneTest(
        wrapLast: true,
        () {
          periodicTimer = Timer.periodic(const Duration(milliseconds: 1), (t) {
            Expect.fail("Unreachable");
          });
        },
        beforeCallback: throwError,
        onError: (e, s) {
          periodicTimer!.cancel();
          expectError(error)(e, s);
        },
      );
      zoneTest(
        wrapLast: true,
        () {
          scheduleMicrotask(() {
            Expect.fail("Unreachable");
          });
        },
        beforeCallback: throwError,
        onError: expectError(error),
      );
      asyncEnd();
    },
    beforeCallback: () {
      throw error2;
    },
  );

  // Inner `run*Callback* runs first, and all `run*s` run before the
  // registered callback.
  zoneTest(
    () {
      asyncStart();
      zoneTest(
        () {
          asyncStart();
          Timer(const Duration(milliseconds: 1), () {
            Expect.fail("Unreachable");
          });
        },
        beforeRun: throwError,
        onError: expectError(error),
      );
      Timer? periodicTimer;
      zoneTest(
        () {
          asyncStart();
          periodicTimer = Timer.periodic(const Duration(milliseconds: 1), (t) {
            Expect.fail("Unreachable");
          });
        },
        beforeRun: throwError,
        onError: (e, s) {
          periodicTimer!.cancel();
          expectError(error)(e, s);
        },
      );
      zoneTest(
        () {
          asyncStart();
          scheduleMicrotask(() {
            Expect.fail("Unreachable");
          });
        },
        beforeRun: throwError,
        onError: expectError(error),
      );
      asyncEnd();
    },
    beforeCallback: () {
      throw error2;
    },
    beforeRun: () {
      throw error2;
    },
  );

  asyncEnd();
}

StackTrace combineStacks(StackTrace s1, StackTrace s2) =>
    StackTrace.fromString("${s1}caused by:\n$s2");
