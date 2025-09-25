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

void test(MyFuture f) {
  Future<int> t1 = f.then((_) async => await new MyFuture<int>.value(3));
  Future<int> t2 = f.then((_) async {
    return await new MyFuture<int>.value(3);
  });
  Future<int> t3 = f.then((_) async => 3);
  Future<int> t4 = f.then((_) async {
    return 3;
  });
  Future<int> t5 = f.then((_) => new MyFuture<int>.value(3));
  Future<int> t6 = f.then((_) {
    return new MyFuture<int>.value(3);
  });
  Future<int> t7 = f.then((_) async => new MyFuture<int>.value(3));
  Future<int> t8 = f.then((_) async {
    return new MyFuture<int>.value(3);
  });
}

main() {}
