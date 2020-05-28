// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:async';
import 'package:expect/expect.dart';

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

@pragma('dart2js:noInline')
test(o) => o is FutureOr<A>;

main() {
  Expect.isTrue(test(new A()));
  Expect.isTrue(test(new FutureMock<A>(new A())));
  Expect.isFalse(test(new B()));
  Expect.isFalse(test(new FutureMock<B>(new B())));
}
