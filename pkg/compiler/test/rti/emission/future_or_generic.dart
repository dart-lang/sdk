// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:async';
import 'package:expect/expect.dart';

/*class: global#Future:checkedInstance*/

/*class: A:checks=[],instance*/
class A<T> {
  @pragma('dart2js:noInline')
  m(o) => o is FutureOr<T>;
}

/*class: B:checkedInstance,checks=[],instance,typeArgument*/
class B {}

// TODO(johnniwinther): Do we need the implied `checkedTypeArgument` from
// the `Future<C>` test in `A.m`?
/*class: C:checkedInstance,typeArgument*/
class C {}

/*class: FutureMock:checks=[$isFuture],instance*/
class FutureMock<T> implements Future<T> {
  final T value;

  FutureMock(this.value);

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> onTimeout()}) => null;

  @override
  Stream<T> asStream() => null;

  @override
  Future<T> whenComplete(FutureOr action()) => null;

  @override
  Future<T> catchError(Function onError, {bool test(bool test(Object error))}) {
    return null;
  }

  @override
  Future<S> then<S>(FutureOr<S> onValue(T value), {Function onError}) => null;
}

main() {
  Expect.isTrue(new A<B>().m(new B()));
  Expect.isTrue(new A<B>().m(new FutureMock<B>(new B())));
  Expect.isFalse(new A<C>().m(new B()));
  Expect.isFalse(new A<C>().m(new FutureMock<B>(new B())));
}
