// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

method1(int i) {
  const dynamic d = 0;
  const dynamic s = '';
  return switch (i) {
    < d => 0,
    > s => 1, // Error: The implicit cast to num is statically known to fail.
    _ => 2,
  };
}

method2(int i) {
  const dynamic d = 0;
  const dynamic p = 3.14;
  return switch (i) {
    < d => 0,
    > p => 1, // Ok.
    _ => 2,
  };
}
