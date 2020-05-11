// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that it is an error to await an expression of type `void`.

import "dart:async";

void v;
List<void> vs = [null];
FutureOr<void> fov;

void main() async {
  await print('');
  //    ^
  // [analyzer] unspecified
  // [cfe] unspecified

  await v;
  //    ^
  // [analyzer] unspecified
  // [cfe] unspecified

  await vs[0];
  //    ^
  // [analyzer] unspecified
  // [cfe] unspecified

  var v2 = vs[0];
  await v2;
  //    ^
  // [analyzer] unspecified
  // [cfe] unspecified

  // A `FutureOr<void>` can be awaited.
  await fov;
}
