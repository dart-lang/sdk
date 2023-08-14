// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that both nullability of type and type argument
// is taken into account in the FutureOr type checks.
// Regression test for https://github.com/dart-lang/sdk/issues/52536.

import 'dart:async';

import 'package:expect/expect.dart';

class C<D, T> {
  final FutureOr<T> Function(D) fn;

  C(this.fn);
}

FutureOr<T>? compute<T extends Object>(int? a) => null;

void main() {
  final c = C<int?, int?>(compute);
  c.fn(42);

  Expect.isTrue(<FutureOr<int>?>[] is List<FutureOr<int?>>);
  Expect.isFalse(
      hasSoundNullSafety && <FutureOr<int?>>[] is List<FutureOr<int>?>);
}
