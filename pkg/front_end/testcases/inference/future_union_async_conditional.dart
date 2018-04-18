// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

class MyFuture<T> implements Future<T> {
  MyFuture() {}
  MyFuture.value(x) {}
  dynamic noSuchMethod(/*@topType=Invocation*/ invocation);
  MyFuture<S> then<S>(FutureOr<S> f(T x), {Function onError}) => null;
}

Future<int> g1(bool x) async {
  return /*info:DOWN_CAST_COMPOSITE*/ x
      ? 42
      : new /*@typeArgs=int*/ Future.value(42);
}

Future<int> g2(bool x) async =>
    /*info:DOWN_CAST_COMPOSITE*/ x
        ? 42
        : new /*@typeArgs=int*/ Future.value(42);
Future<int> g3(bool x) async {
  var /*@type=Object*/ y = x ? 42 : new /*@typeArgs=int*/ Future.value(42);
  return /*info:DOWN_CAST_COMPOSITE*/ y;
}

main() {}
