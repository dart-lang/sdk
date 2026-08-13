// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation) => null;
  MyFuture<S> then<S>(FutureOr<S> f(T x), {Function? onError}) => throw '';
}

void test(Future<bool> f) {
  Future<int> t1 = f.then(
    (x) async => x ? 2 : await new MyFuture<int>.value(3),
  );
  Future<int> t2 = f.then((x) async {
    return /*info:DOWN_CAST_COMPOSITE*/ await x
        ? 2
        : new MyFuture<int>.value(3);
  });
  Future<int> t5 = f.then(
    /*info:INFERRED_TYPE_CLOSURE,error:INVALID_CAST_FUNCTION_EXPR*/
    (x) => x ? 2 : new MyFuture<int>.value(3),
  );
  Future<int> t6 = f.then((x) {
    return /*info:DOWN_CAST_COMPOSITE*/ x ? 2 : new MyFuture<int>.value(3);
  });
}

main() {}
