// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that if an `await` expression appears in a syntactic position that
// doesn't impose a context on it, it supplies a context of `FutureOr<_>` to its
// operand, rather than `_` (which was the behavior prior to fixing
// https://github.com/dart-lang/language/issues/3648).

// Contexts of `FutureOr<_>` and `_` are difficult to distinguish. This test
// distinguishes them by awaiting the expression `((null as Future<B>?) ??
// (Future.value(C())..expectStaticType<Exactly<Future<C>>>()))`, where `C` is a
// class that extends `B`.
//
// This works because, if it is analyzed in context `Future<_>`, then:
// - The RHS of `??` is analyzed in context `Future<_>`.
// - Therefore downwards inference doesn't impose any constraint on the type
//   parameter of `Future.value(C())`.
// - Therefore `Future.value(C())` gets its type parameter from upwards
//   inference.
// - So it receives a type parameter of `C`.
// - So the static type of `Future.value(C())` is `Future<C>`.
//
// Whereas if it is analyzed in context `_`, then:
// - The static type of the LHS of `??` is used as the context for the RHS.
//   That is, the RHS is analyzed in context `Future<B>?`.
// - Therefore downwards inference constraints the type parameter of
//   `Future.value(C())` to `B`.
// - So the static type of `Future.value(C())` is `Future<B>`.

import 'package:expect/static_type_helper.dart';

class B {
  var prop;
  void method() {}
}

class C extends B {}

main() async {
  // Initializer part of a C-style for loop
  for (await ((null as Future<B>?) ??
          (Future.value(C())..expectStaticType<Exactly<Future<C>>>()));
      false;) {}

  // Updater part of a C-style for loop
  for (var i = 0;
      i < 1;
      i++,
      await ((null as Future<B>?) ??
          (Future.value(C())..expectStaticType<Exactly<Future<C>>>()))) {}

  // Target of a property set
  (await ((null as Future<B>?) ??
          (Future.value(C())..expectStaticType<Exactly<Future<C>>>())))
      .prop = 0;

  // Target of a property get
  (await ((null as Future<B>?) ??
          (Future.value(C())..expectStaticType<Exactly<Future<C>>>())))
      .prop;

  // Assert statement message
  try {
    assert(
        false,
        await ((null as Future<B>?) ??
            (Future.value(C())..expectStaticType<Exactly<Future<C>>>())));
  } on AssertionError {}

  // Expression statement
  await ((null as Future<B>?) ??
      (Future.value(C())..expectStaticType<Exactly<Future<C>>>()));

  // Interpolation expression
  "${await ((null as Future<B>?) ?? (Future.value(C())..expectStaticType<Exactly<Future<C>>>()))}";

  // Target of a method invocation
  (await ((null as Future<B>?) ??
          (Future.value(C())..expectStaticType<Exactly<Future<C>>>())))
      .method();
}
