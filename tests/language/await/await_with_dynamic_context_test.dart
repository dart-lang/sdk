// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that if an `await` expression is analyzed in a `dynamic` context, it
// supplies a context of `FutureOr<_>` to its operand, rather than `dynamic`
// (which was the front end behavior prior to fixing
// https://github.com/dart-lang/language/issues/3649).

// Contexts of `FutureOr<_>` and `dynamic` are difficult to distinguish. This
// test distinguishes them by awaiting the expression `id(((null as Future<B>?)
// ??  (Future.value(C())..expectStaticType<Exactly<Future<C>>>())))`, where `C`
// is a class that extends `B`, and `id` is a generic identity function having
// type `T Function<T>(T)`.
//
// This works because, if it is analyzed in context `Future<_>`, then:
// - The call to `id` is analyzed in context `Future<_>`.
// - Therefore the `??` expression is analyzed in context `Future<_>`.
// - Therefore the RHS of `??` is analyzed in context `Future<_>`.
// - Therefore downwards inference doesn't impose any constraint on the type
//   parameter of `Future.value(C())`.
// - Therefore `Future.value(C())` gets its type parameter from upwards
//   inference.
// - So it receives a type parameter of `C`.
// - So the static type of `Future.value(C())` is `Future<C>`.
//
// Whereas if it is analyzed in context `dynamic`, then:
// - The call to `id` is analyzed in context `dynamic`.
// - Therefore the `??` expression is analyzed in context `_`.
// - Therefore the static type of the LHS of `??` is used as the context for the
//   RHS. That is, the RHS is analyzed in context `Future<B>?`.
// - Therefore downwards inference constraints the type parameter of
//   `Future.value(C())` to `B`.
// - So the static type of `Future.value(C())` is `Future<B>`.

import '../static_type_helper.dart';

class B {}

class C extends B {}

T id<T>(T t) => t;

main() async {
  dynamic x = await id(((null as Future<B>?) ??
      (Future.value(C())..expectStaticType<Exactly<Future<C>>>())));
}
