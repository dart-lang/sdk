// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Helper library for await_type_check_with_dynamic_loading_test.dart.

import 'await_type_check_with_dynamic_loading_test.dart';

class D implements A, Future<A> {
  final Future<A> impl;

  D(A value) : impl = Future.value(value);

  @override
  asStream() => impl.asStream();

  @override
  catchError(error, {test}) => impl.catchError(error, test: test);

  @override
  then<R>(onValue, {onError}) => impl.then(onValue, onError: onError);

  @override
  timeout(timeLimit, {onTimeout}) =>
      impl.timeout(timeLimit, onTimeout: onTimeout);

  @override
  whenComplete(action) => impl.whenComplete(action);
}

makeNewFuture() {
  final obj = B();
  return (obj, D(obj));
}
