// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N await_only_futures`

import 'dart:async';

bad() async {
  print(await 23); // LINT
}

good() async {
  print(await new Future.value(23));
}

Future awaitWrapper(dynamic future) async {
  return await future; // OK
}

class CancellableFuture<T> implements Future<T> {
  @override
  Stream<T> asStream() {
    throw new Exception('Not supported.');
  }

  @override
  Future<T> catchError(Function onError, {bool test(Object error)}) {
    throw new Exception('Not supported.');
  }


  @override
  Future<T> timeout(Duration timeLimit, {onTimeout()}) {
    throw new Exception('Not supported.');
  }

  @override
  Future<T> whenComplete(action()) {
    throw new Exception('Not supported.');
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(T value) onValue, {Function onError}) {
    throw new Exception('Not supported.');
  }
}

Future awaitCancellableFuture(dynamic future) async {
  return await new CancellableFuture(); // OK
}

Future<String> awaitFutureOr(FutureOr<String> callback()) async {
  return await callback(); // OK
}

allow_await_null() async {
  await null; // OK
}
