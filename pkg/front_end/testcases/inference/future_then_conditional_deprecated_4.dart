// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(T x) {}
  dynamic noSuchMethod(invocation);
  MyFuture<S> then<S>(dynamic f(T x), {Function onError}) => null;
}

void main() {
  MyFuture<bool> f;
  MyFuture<int> t1 = /*@promotedType=none*/ f.then(
      /*@returnType=Future<int>*/ (/*@type=bool*/ x) async =>
          x ? 2 : await new MyFuture<int>.value(3));
  MyFuture<int> t2 = /*@promotedType=none*/ f
      .then(/*@returnType=Future<int>*/ (/*@type=bool*/ x) async {
    return /*info:DOWN_CAST_COMPOSITE*/ await x
        ? 2
        : new MyFuture<int>.value(3);
  });
  MyFuture<int> t5 = /*@promotedType=none*/ f.then(
      /*@returnType=Object*/ (/*@type=bool*/ x) =>
          x ? 2 : new MyFuture<int>.value(3));
  MyFuture<int> t6 = /*@promotedType=none*/ f.then(
      /*@returnType=FutureOr<int>*/ (/*@type=bool*/ x) {
    return /*info:DOWN_CAST_COMPOSITE*/ x ? 2 : new MyFuture<int>.value(3);
  });
}
