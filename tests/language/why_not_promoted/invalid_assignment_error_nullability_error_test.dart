// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test contains a test case for each condition that can lead to the front
// end's `InvalidAssignmentErrorNullability` or
// `InvalidAssignmentErrorPartNullability` errors, for which we wish to report
// "why not promoted" context information.

class C1 {
  List<int>? bad;
}

test(C1 c) sync* {
  if (c.bad == null) return;
  yield* c.bad;
  //     ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
  // [analyzer] COMPILE_TIME_ERROR.YIELD_OF_INVALID_TYPE
  //       ^
  // [cfe] A value of type 'List<int>?' can't be assigned to a variable of type 'Iterable<dynamic>'.
}
