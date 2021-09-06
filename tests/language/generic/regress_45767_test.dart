// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:expect/expect.dart';

// Regression test for https://github.com/dart-lang/sdk/issues/45767.

class I<T> {}

class F<E extends F<E>> extends I<E> {}

// Extending F forces DDC to defer the superclass and trigger the bug
class A<T> extends F<A<Object?>> {}

// Nullability on a type argument in the deferred type.
class B<T> extends F<B<T?>> {}

// Nullability on a FutureOr in the deferred type.
class C<T> extends F<C<FutureOr<int>?>> {}

// Reference the current type inside a FutureOr in the deferred type.
class D<T> extends F<D<FutureOr<D?>>> {}

// Nullability and normalization on FutureOrTypes in the deferred type.
class G<T> extends F<G<FutureOr<Null>?>> {}

void main() {
  Expect.isTrue(A<bool>() is I<A<Object?>>);
  Expect.equals(!hasSoundNullSafety, A<bool>() is I<A<Object>>);
  Expect.isTrue(B<bool>() is I<B<bool?>>);
  Expect.equals(!hasSoundNullSafety, B<bool>() is I<B<bool>>);
  Expect.isTrue(C<bool>() is I<C<FutureOr<int>?>>);
  Expect.equals(!hasSoundNullSafety, C<bool>() is I<C<FutureOr<int>>>);
  Expect.isTrue(D<bool>() is I<D<FutureOr<D?>>>);
  Expect.equals(!hasSoundNullSafety, D<bool>() is I<D<FutureOr<D>>>);
  Expect.isTrue(G<bool>() is I<G<Future<Null>?>>);
  Expect.equals(!hasSoundNullSafety, G<bool>() is I<G<Future<Null>>>);
}
