// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patternVariableAssignment((int, String) r) {
  var (x, s) = r;
  return () => x;
}

orPatternVariable(dynamic x) {
  switch (x) {
    case int y:
    case String(length: int y):
      return () => y;
    default:
      return () => 0;
  }
}
