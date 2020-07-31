// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  // Non-bool condition expression.
  dynamic nonBool = 3;
  Expect.throwsTypeError(() => <int>[for (; nonBool;) 1]);
  Expect.throwsTypeError(() => <int, int>{for (; nonBool;) 1: 1});
  Expect.throwsTypeError(() => <int>{for (; nonBool;) 1});
}
