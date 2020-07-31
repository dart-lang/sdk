// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// [NNBD non-migrated] This test has no NNBD equivalent.
// In NNBD, you are not allowed to await `void` and the corresponding test
// is await_void_error_test.dart

// Test that it is not an error to await an expression of type `void`.

import "dart:async";

void v;
List<void> vs = [null];
FutureOr<void> fov;

void main() async {
  await print('');
  await v;
  await vs[0];
  var v2 = vs[0];
  await v2;
  await fov;
}
