// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak
import 'package:expect/expect.dart';

void main() {
  // Null condition expression.
  dynamic nullBool = null;
  Expect.throwsAssertionError(() => <int>[for (; nullBool;) 1]);
  Expect.throwsAssertionError(() => <int, int>{for (; nullBool;) 1: 1});
  Expect.throwsAssertionError(() => <int>{for (; nullBool;) 1});

  // Null iterable.
  dynamic nullIterable = null;
  Expect.throwsAssertionError(() => <int>[for (var i in nullIterable) 1]);
  Expect.throwsAssertionError(
      () => <int, int>{for (var i in nullIterable) 1: 1});
  Expect.throwsAssertionError(() => <int>{for (var i in nullIterable) 1});
}
