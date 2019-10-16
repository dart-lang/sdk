// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void assertStatement(Object x) {
  assert((x is int ? /*int*/ x : throw 'foo') == 0);
  // TODO(paulberry): should not be promoted because the assertion won't execute
  // in release mode.  See https://github.com/dart-lang/sdk/issues/38761.
  /*int*/ x;
}
