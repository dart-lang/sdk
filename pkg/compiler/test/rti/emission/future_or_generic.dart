// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:compiler/src/util/testing.dart';

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
  Future<T> timeout(Duration timeLimit, {FutureOr<T> onTimeout()?}) => this;

  @override
  Stream<T> asStream() => const Stream.empty();

  @override
  Future<T> whenComplete(FutureOr action()) => this;

  @override
  Future<T> catchError(Function onError,
      {bool test(bool test(Object error))?}) {
    return this;
  }

  @override
  Future<S> then<S>(FutureOr<S> onValue(T value), {Function? onError}) =>
      Future.value(onValue(value));
}

main() {
  makeLive(new A<B>().m(new B()));
  makeLive(new A<B>().m(new FutureMock<B>(new B())));
  makeLive(new A<C>().m(new B()));
  makeLive(new A<C>().m(new FutureMock<B>(new B())));
}
