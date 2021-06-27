// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";

main() {
  var stack = StackTrace.fromString("for testing");
  var error = Object();
  var stateError = StateError("test");

  asyncStart();

  {
    // Match any error.
    asyncStart();
    var future = Future.error(error, stack);
    future.onError((e, s) {
      Expect.identical(error, e);
      Expect.identical(stack, s);
      asyncEnd();
    });
  }

  {
    // With matching test.
    asyncStart();
    var future = Future.error(error, stack);
    future.onError((e, s) {
      Expect.identical(error, e);
      Expect.identical(stack, s);
      asyncEnd();
    }, test: (o) => true);
  }

  {
    // With failing test.
    asyncStart();
    var future = Future.error(error, stack);
    var onErrorFuture = future.onError((e, s) {
      Expect.fail('unreachable');
    }, test: (o) => false);
    onErrorFuture.catchError((e, s) {
      Expect.identical(error, e);
      Expect.identical(stack, s);
      asyncEnd();
    });
  }

  {
    // With matching type.
    asyncStart();
    var future = Future.error(stateError, stack);
    future.onError<StateError>((e, s) {
      Expect.identical(stateError, e);
      Expect.identical(stack, s);
      asyncEnd();
    });
  }

  {
    // With non-matching type.
    asyncStart();
    var future = Future.error(stateError, stack);
    var onErrorFuture = future.onError<ArgumentError>((e, s) {
      Expect.fail('unreachable');
    });
    onErrorFuture.catchError((e, s) {
      Expect.identical(stateError, e);
      Expect.identical(stack, s);
      asyncEnd();
    });
  }

  {
    // With non-matching type and matching test.
    asyncStart();
    var future = Future.error(stateError, stack);
    var onErrorFuture = future.onError<ArgumentError>((e, s) {
      Expect.fail('unreachable');
    }, test: (ArgumentError e) => true);
    onErrorFuture.catchError((e, s) {
      Expect.identical(stateError, e);
      Expect.identical(stack, s);
      asyncEnd();
    });
  }

  {
    // With matching type and matching test.
    asyncStart();
    var future = Future.error(stateError, stack);
    future.onError<StateError>((e, s) {
      Expect.identical(stateError, e);
      Expect.identical(stack, s);
      asyncEnd();
    }, test: (StateError e) => true);
  }

  {
    // With matching type and non-matching test.
    asyncStart();
    var future = Future.error(stateError, stack);
    var onErrorFuture = future.onError<StateError>((e, s) {
      Expect.fail('unreachable');
    }, test: (StateError e) => false);
    onErrorFuture.catchError((e, s) {
      Expect.identical(stateError, e);
      Expect.identical(stack, s);
      asyncEnd();
    });
  }
  asyncEnd();
}
