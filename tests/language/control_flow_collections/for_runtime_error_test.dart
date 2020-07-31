// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  // Cast for variable.
  dynamic nonInt = "string";
  Expect.throwsTypeError(() => <int>[for (int i = nonInt; false;) 1]);
  Expect.throwsTypeError(() => <int, int>{for (int i = nonInt; false;) 1: 1});
  Expect.throwsTypeError(() => <int>{for (int i = nonInt; false;) 1});

  // Cast for-in variable.
  dynamic nonIterable = 3;
  Expect.throwsTypeError(() => <int>[for (int i in nonIterable) 1]);
  Expect.throwsTypeError(() => <int, int>{for (int i in nonIterable) 1: 1});
  Expect.throwsTypeError(() => <int>{for (int i in nonIterable) 1});

  // Wrong element type.
  Expect.throwsTypeError(() => <int>[for (var i = 0; i < 1; i++) nonInt]);
  Expect.throwsTypeError(
      () => <int, int>{for (var i = 0; i < 1; i++) nonInt: 1});
  Expect.throwsTypeError(
      () => <int, int>{for (var i = 0; i < 1; i++) 1: nonInt});
  Expect.throwsTypeError(() => <int>{for (var i = 0; i < 1; i++) nonInt});
}
