// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Checks that Future<Future<int>> is a valid type and that futures can contain
// and complete other futures.

// This essentially checks that `FutureOr<X>` is treated correctly depending
// on what `X` is.

import 'dart:async';
import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";

main() {
  asyncStart();

  // Helper values.
  Future<Null> nullFuture = Future<Null>.value(null);

  var stack = StackTrace.current;
  var error = ArgumentError("yep");
  Future<Null> errorFuture = Future<Null>.error(error, stack)
    ..catchError((_) => null);
  Future<int> fi(int n) => Future<int>.value(n);

  // Tests that Future<Future<int>> can be created.
  Future<Future<int>> ffi(n) => Future<Future<int>>.value(fi(n));

  asyncTest(() {
    return expectFutureFutureInt(ffi(0), 0);
  });

  // Check `Future.then`'s callback.

  asyncTest(() {
    Future<int> future = nullFuture.then<int>((_) => fi(1));
    return expectFutureInt(future, 1);
  });

  asyncTest(() {
    Future<Future<int>> future = nullFuture.then<Future<int>>((_) => fi(2));
    return expectFutureFutureInt(future, 2);
  });

  asyncTest(() {
    Future<Future<int>> future = nullFuture.then<Future<int>>((_) => ffi(3));
    return expectFutureFutureInt(future, 3);
  });

  // Check `Future.then`'s `onError`.

  asyncTest(() {
    Future<int> future =
        errorFuture.then<int>((_) => -1, onError: (_) => fi(4));
    return expectFutureInt(future, 4);
  });

  asyncTest(() {
    Future<Future<int>> future =
        errorFuture.then<Future<int>>((_) => fi(-1), onError: (_) => fi(5));
    return expectFutureFutureInt(future, 5);
  });

  asyncTest(() {
    Future<Future<int>> future =
        errorFuture.then<Future<int>>((_) => fi(-1), onError: (_) => ffi(6));
    return expectFutureFutureInt(future, 6);
  });

  // Checkc Future.catchError, it's FutureOr is based on the
  // original future's type.

  asyncTest(() {
    Future<int> errorFuture = Future<int>.error(error, stack);
    Future<int> future = errorFuture.catchError((_) => fi(7));
    return expectFutureInt(future, 7);
  });

  asyncTest(() {
    Future<Future<int>> errorFuture = Future<Future<int>>.error(error, stack);
    Future<Future<int>> future = errorFuture.catchError((_) => fi(8));
    return expectFutureFutureInt(future, 8);
  });

  asyncTest(() {
    Future<Future<int>> errorFuture = Future<Future<int>>.error(error, stack);
    Future<Future<int>> future = errorFuture.catchError((_) => ffi(9));
    return expectFutureFutureInt(future, 9);
  });

  // Check Completer.complete.

  asyncTest(() {
    var completer = Completer<int>()..complete(fi(10));
    return expectFutureInt(completer.future, 10);
  });

  asyncTest(() {
    var completer = Completer<Future<int>>()..complete(fi(11));
    return expectFutureFutureInt(completer.future, 11);
  });

  asyncTest(() {
    var completer = Completer<Future<int>>()..complete(ffi(12));
    return expectFutureFutureInt(completer.future, 12);
  });

  // Future<Object> works correctly when Object is another Future.
  asyncTest(() {
    Future<Object> future = nullFuture.then<Object>((_) => fi(13));
    Expect.type<Future<Object>>(future);
    Expect.notType<Future<int>>(future);
    return future.then<void>((o) {
      Expect.equals(13, o);
    });
  });

  asyncTest(() {
    Future<Object> future = nullFuture.then<Object>((_) => ffi(14));
    Expect.type<Future<Object>>(future);
    Expect.notType<Future<int>>(future);
    Expect.notType<Future<Future<int>>>(future);
    return future.then<void>((v) => expectFutureInt(v, 14));
  });

  asyncTest(() {
    Future<Object> future =
        errorFuture.then<Object>((_) => -1, onError: (_) => fi(15));
    Expect.type<Future<Object>>(future);
    Expect.notType<Future<int>>(future);
    return future.then<void>((o) {
      Expect.equals(15, o);
    });
  });

  asyncTest(() {
    Future<Object> future =
        errorFuture.then<Object>((_) => -1, onError: (_) => ffi(16));
    Expect.type<Future<Object>>(future);
    Expect.notType<Future<int>>(future);
    Expect.notType<Future<Future<int>>>(future);
    return future.then<void>((v) => expectFutureInt(v, 16));
  });

  asyncTest(() {
    Future<Object> errorFuture = Future<Object>.error(error, stack);
    Future<Object> future = errorFuture.catchError((_) => fi(17));
    Expect.type<Future<Object>>(future);
    Expect.notType<Future<int>>(future);
    return future.then<void>((o) {
      Expect.equals(17, o);
    });
  });

  asyncTest(() {
    Future<Object> errorFuture = Future<Object>.error(error, stack);
    Future<Object> future = errorFuture.catchError((_) => ffi(18));
    Expect.type<Future<Object>>(future);
    Expect.notType<Future<int>>(future);
    Expect.notType<Future<Future<int>>>(future);
    return future.then<void>((v) => expectFutureInt(v, 18));
  });

  asyncEnd();
}

// Checks that future is a Future<Future<int>> containing the value Future<int>
// which then contains the value 42.
Future<void> expectFutureFutureInt(dynamic future, int n) {
  Expect.type<Future<Future<int>>>(future);
  asyncStart();
  return future.then<void>((dynamic v) {
    Expect.type<Future<int>>(v, "$n");
    return expectFutureInt(v, n).then(asyncSuccess);
  });
}

Future<void> expectFutureInt(dynamic future, int n) {
  Expect.type<Future<int>>(future);
  asyncStart();
  return future.then<void>((dynamic v) {
    Expect.type<int>(v, "$n");
    Expect.equals(n, v);
    asyncEnd();
  });
}
