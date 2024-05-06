// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:compiler/src/util/testing.dart';

/*class: global#Future:checkedInstance*/

/*class: A:checkedInstance,checkedTypeArgument,checks=[],instance,typeArgument*/
class A {}

/*class: B:checkedInstance,checks=[],instance,typeArgument*/
class B {}

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

@pragma('dart2js:noInline')
test(o) => o is FutureOr<A>;

main() {
  makeLive(test(new A()));
  makeLive(test(new FutureMock<A>(new A())));
  makeLive(test(new B()));
  makeLive(test(new FutureMock<B>(new B())));
}
