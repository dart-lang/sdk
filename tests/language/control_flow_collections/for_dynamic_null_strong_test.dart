// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong
import 'package:expect/expect.dart';

void main() {
  // Null condition expression.
  dynamic nullBool = null;
  Expect.throwsTypeError(() => <int>[for (; nullBool;) 1]);
  Expect.throwsTypeError(() => <int, int>{for (; nullBool;) 1: 1});
  Expect.throwsTypeError(() => <int>{for (; nullBool;) 1});

  // Null iterable.
  dynamic nullIterable = null;
  Expect.throwsTypeError(() => <int>[for (var i in nullIterable) 1]);
  Expect.throwsTypeError(() => <int, int>{for (var i in nullIterable) 1: 1});
  Expect.throwsTypeError(() => <int>{for (var i in nullIterable) 1});
}
