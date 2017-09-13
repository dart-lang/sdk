// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.test.cancelable_future_test;

import 'dart:async';

import 'package:analyzer/src/cancelable_future.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:watcher/src/utils.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CancelableCompleterTests);
    defineReflectiveTests(CancelableFutureTests);
  });
}

@reflectiveTest
class CancelableCompleterTests {
  CancelableCompleter<Object> completer;
  int cancelCount = 0;

  void setUp() {
    completer = new CancelableCompleter<Object>(() {
      cancelCount++;
    });
  }

  Future test_cancel_after_cancel() {
    // It is permissible to cancel multiple times, but only the first
    // cancellation has any effect.
    expect(cancelCount, 0);
    completer.future.cancel();
    expect(cancelCount, 1);
    completer.future.cancel();
    expect(cancelCount, 1);
    // Make sure the future still completes with error.
    return completer.future
        .then((_) {
          fail('Expected error completion');
        }, onError: (error) {
          expect(error, new isInstanceOf<FutureCanceledError>());
          // And make sure nothing else happens.
        })
        .then((_) => pumpEventQueue())
        .then((_) {
          expect(completer.isCompleted, isFalse);
          expect(cancelCount, 1);
        });
  }

  Future test_cancel_after_chaining() {
    bool callbackInvoked = false;
    completer.future.then((_) {
      fail('Expected error completion');
    }, onError: (error) {
      expect(callbackInvoked, isFalse);
      expect(error, new isInstanceOf<FutureCanceledError>());
      callbackInvoked = true;
    });
    expect(cancelCount, 0);
    completer.future.cancel();
    // The cancel callback should have been invoked immediately.
    expect(cancelCount, 1);
    // But the completer should remain in the "not completed" state.
    expect(completer.isCompleted, isFalse);
    // The callback should be deferred to a microtask.
    expect(callbackInvoked, isFalse);
    return pumpEventQueue().then((_) {
      expect(callbackInvoked, isTrue);
      expect(completer.isCompleted, isFalse);
      expect(cancelCount, 1);
    });
  }

  Future test_cancel_after_complete() {
    Object obj = new Object();
    completer.complete(obj);
    completer.future.cancel();
    // The cancel callback should not have been invoked, because it was too
    // late to cancel.
    expect(cancelCount, 0);
    // Make sure the future still completes with the object.
    return completer.future
        .then((result) {
          expect(result, same(obj));
          // And make sure nothing else happens.
        })
        .then((_) => pumpEventQueue())
        .then((_) {
          expect(completer.isCompleted, isTrue);
          expect(cancelCount, 0);
        });
  }

  Future test_cancel_before_chaining() {
    completer.future.cancel();
    // The cancel callback should have been invoked immediately.
    expect(cancelCount, 1);
    // But the completer should remain in the "not completed" state.
    expect(completer.isCompleted, isFalse);
    bool callbackInvoked = false;
    completer.future.then((_) {
      fail('Expected error completion');
    }, onError: (error) {
      expect(callbackInvoked, isFalse);
      expect(error, new isInstanceOf<FutureCanceledError>());
      callbackInvoked = true;
    });
    // The callback should be deferred to a microtask.
    expect(callbackInvoked, isFalse);
    expect(completer.isCompleted, isFalse);
    return pumpEventQueue().then((_) {
      expect(callbackInvoked, isTrue);
      expect(completer.isCompleted, isFalse);
      expect(cancelCount, 1);
    });
  }

  Future test_complete_after_cancel() {
    completer.future.cancel();
    // The cancel callback should have been invoked immediately.
    expect(cancelCount, 1);
    // Completing should have no effect other than to set the isCompleted
    // flag.
    expect(completer.isCompleted, isFalse);
    Object obj = new Object();
    completer.complete(obj);
    expect(completer.isCompleted, isTrue);
    // Make sure the future still completer with error.
    return completer.future
        .then((_) {
          fail('Expected error completion');
        }, onError: (error) {
          expect(error, new isInstanceOf<FutureCanceledError>());
          // And make sure nothing else happens.
        })
        .then((_) => pumpEventQueue())
        .then((_) {
          expect(completer.isCompleted, isTrue);
          expect(cancelCount, 1);
        });
  }

  Future test_complete_after_chaining() {
    Object obj = new Object();
    bool callbackInvoked = false;
    completer.future.then((result) {
      expect(callbackInvoked, isFalse);
      expect(result, same(obj));
      callbackInvoked = true;
    }, onError: (error) {
      fail('Expected successful completion');
    });
    expect(completer.isCompleted, isFalse);
    // Running the event loop should have no effect since the completer hasn't
    // been completed yet.
    return pumpEventQueue()
        .then((_) {
          completer.complete(obj);
          expect(completer.isCompleted, isTrue);
          // The callback should be deferred to a microtask.
          expect(callbackInvoked, isFalse);
        })
        .then((_) => pumpEventQueue())
        .then((_) {
          expect(callbackInvoked, isTrue);
          expect(completer.isCompleted, isTrue);
          expect(cancelCount, 0);
        });
  }

  void test_complete_after_complete() {
    // As with an ordinary Completer, calling complete() (or completeError)
    // after calling complete() should throw an exception.
    completer.complete();
    expect(() {
      completer.complete();
    }, throwsA(new isInstanceOf<StateError>()));
    expect(() {
      completer.completeError(new Object());
    }, throwsA(new isInstanceOf<StateError>()));
  }

  void test_complete_after_completeError() {
    // As with an ordinary Completer, calling complete() (or completeError)
    // after calling completeError() should throw an exception.
    completer.completeError(new Object());
    expect(() {
      completer.complete();
    }, throwsA(new isInstanceOf<StateError>()));
    expect(() {
      completer.completeError(new Object());
    }, throwsA(new isInstanceOf<StateError>()));
    // Now absorb the error that's in the completer's future.
    completer.future.catchError((_) => null);
  }

  Future test_complete_before_chaining() {
    Object obj = new Object();
    completer.complete(obj);
    expect(completer.isCompleted, isTrue);
    bool callbackInvoked = false;
    completer.future.then((result) {
      expect(callbackInvoked, isFalse);
      expect(result, same(obj));
      callbackInvoked = true;
    }, onError: (error) {
      fail('Expected successful completion');
    });
    // The callback should be deferred to a microtask.
    expect(callbackInvoked, isFalse);
    expect(completer.isCompleted, isTrue);
    return pumpEventQueue().then((_) {
      expect(callbackInvoked, isTrue);
      expect(completer.isCompleted, isTrue);
      expect(cancelCount, 0);
    });
  }

  Future test_completeError_after_cancel() {
    completer.future.cancel();
    // The cancel callback should have been invoked immediately.
    expect(cancelCount, 1);
    // Completing should have no effect other than to set the isCompleted
    // flag.
    expect(completer.isCompleted, isFalse);
    Object obj = new Object();
    completer.completeError(obj);
    expect(completer.isCompleted, isTrue);
    // Make sure the future still completes with error.
    return completer.future
        .then((_) {
          fail('Expected error completion');
        }, onError: (error) {
          expect(error, new isInstanceOf<FutureCanceledError>());
          // And make sure nothing else happens.
        })
        .then((_) => pumpEventQueue())
        .then((_) {
          expect(completer.isCompleted, isTrue);
          expect(cancelCount, 1);
        });
  }

  Future test_completeError_after_chaining() {
    Object obj = new Object();
    bool callbackInvoked = false;
    completer.future.then((_) {
      fail('Expected error completion');
    }, onError: (error) {
      expect(callbackInvoked, isFalse);
      expect(error, same(obj));
      callbackInvoked = true;
    });
    expect(completer.isCompleted, isFalse);
    // Running the event loop should have no effect since the completer hasn't
    // been completed yet.
    return pumpEventQueue()
        .then((_) {
          completer.completeError(obj);
          expect(completer.isCompleted, isTrue);
          // The callback should be deferred to a microtask.
          expect(callbackInvoked, isFalse);
        })
        .then((_) => pumpEventQueue())
        .then((_) {
          expect(callbackInvoked, isTrue);
          expect(completer.isCompleted, isTrue);
          expect(cancelCount, 0);
        });
  }

  Future test_completeError_before_chaining() {
    Object obj = new Object();
    completer.completeError(obj);
    expect(completer.isCompleted, isTrue);
    bool callbackInvoked = false;
    completer.future.then((_) {
      fail('Expected error completion');
    }, onError: (error) {
      expect(callbackInvoked, isFalse);
      expect(error, same(obj));
      callbackInvoked = true;
    });
    // The callback should be deferred to a microtask.
    expect(callbackInvoked, isFalse);
    expect(completer.isCompleted, isTrue);
    return pumpEventQueue().then((_) {
      expect(callbackInvoked, isTrue);
      expect(completer.isCompleted, isTrue);
      expect(cancelCount, 0);
    });
  }

  void test_initialState() {
    expect(completer.isCompleted, isFalse);
    expect(cancelCount, 0);
  }
}

@reflectiveTest
class CancelableFutureTests {
  Future test_defaultConstructor_returnFuture() {
    Object obj = new Object();
    bool callbackInvoked = false;
    new CancelableFuture(() => new Future(() => obj)).then((result) {
      expect(callbackInvoked, isFalse);
      expect(result, same(obj));
      callbackInvoked = true;
    }, onError: (error) {
      fail('Expected successful completion');
    });
    expect(callbackInvoked, isFalse);
    return pumpEventQueue().then((_) {
      expect(callbackInvoked, isTrue);
    });
  }

  Future test_defaultConstructor_returnValue() {
    Object obj = new Object();
    bool callbackInvoked = false;
    new CancelableFuture(() => obj).then((result) {
      expect(callbackInvoked, isFalse);
      expect(result, same(obj));
      callbackInvoked = true;
    }, onError: (error) {
      fail('Expected successful completion');
    });
    expect(callbackInvoked, isFalse);
    return pumpEventQueue().then((_) {
      expect(callbackInvoked, isTrue);
    });
  }

  Future test_defaultConstructor_throwException() {
    Object obj = new Object();
    bool callbackInvoked = false;
    new CancelableFuture(() {
      throw obj;
    }).then((result) {
      fail('Expected error completion');
    }, onError: (error) {
      expect(callbackInvoked, isFalse);
      expect(error, same(obj));
      callbackInvoked = true;
    });
    expect(callbackInvoked, isFalse);
    return pumpEventQueue().then((_) {
      expect(callbackInvoked, isTrue);
    });
  }

  Future test_delayed_noCallback() {
    DateTime start = new DateTime.now();
    return new CancelableFuture.delayed(new Duration(seconds: 1))
        .then((result) {
      DateTime end = new DateTime.now();
      expect(result, isNull);
      expect(end.difference(start).inMilliseconds > 900, isTrue);
    });
  }

  Future test_delayed_withCallback() {
    Object obj = new Object();
    DateTime start = new DateTime.now();
    return new CancelableFuture.delayed(new Duration(seconds: 1), () {
      DateTime end = new DateTime.now();
      expect(end.difference(start).inMilliseconds > 900, isTrue);
      return obj;
    }).then((result) {
      expect(result, same(obj));
    });
  }

  Future test_error() {
    Object obj = new Object();
    return new CancelableFuture.error(obj).then((result) {
      fail('Expected error completion');
    }, onError: (error) {
      expect(error, same(obj));
    });
  }

  Future test_microtask() {
    Object obj = new Object();
    bool callbackInvoked = false;
    new CancelableFuture.microtask(() => obj).then((result) {
      expect(callbackInvoked, isFalse);
      expect(result, same(obj));
      callbackInvoked = true;
    }, onError: (error) {
      fail('Expected successful completion');
    });
    expect(callbackInvoked, isFalse);
    return pumpEventQueue().then((_) {
      expect(callbackInvoked, isTrue);
    });
  }

  Future test_sync() {
    Object obj = new Object();
    bool callbackInvoked = false;
    new CancelableFuture.sync(() => obj).then((result) {
      expect(callbackInvoked, isFalse);
      expect(result, same(obj));
      callbackInvoked = true;
    }, onError: (error) {
      fail('Expected successful completion');
    });
    expect(callbackInvoked, isFalse);
    return pumpEventQueue().then((_) {
      expect(callbackInvoked, isTrue);
    });
  }

  Future test_value() {
    Object obj = new Object();
    return new CancelableFuture.value(obj).then((result) {
      expect(result, same(obj));
    }, onError: (error) {
      fail('Expected successful completion');
    });
  }
}
