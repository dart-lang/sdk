// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the operand for a `throw` expression is type inferred using a
// context of `Object` (previously it was `_`--see
// https://github.com/dart-lang/sdk/issues/56065).

import 'dart:async';

import '../static_type_helper.dart';

main() async {
  // Note: `contextType(...)..expectStaticType<...>()` can't statically
  // distinguish between a context of `dynamic` and a context of `Object`, since
  // `exp..expectStaticType<Anything>()` is statically allowed if `exp` has a
  // static type of `dynamic`. So to be sure we have the context we think we
  // have, we use `await`, which causes the context to be wrapped in `FutureOr`.
  try {
    throw await contextType(Future.value('foo'))
      ..expectStaticType<Exactly<FutureOr<Object>>>();
  } on String catch (_) {}
}
