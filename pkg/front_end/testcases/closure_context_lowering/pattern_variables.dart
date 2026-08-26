// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

patternVariableAssignment((int, String) r) {
  var (x, s) = r;
  return () => x;
}

joinedVariableMultipleHeads(dynamic x) {
  switch (x) {
    case int y:
    case String(length: int y):
      return () => y;
    default:
      return () => 0;
  }
}

joinedVariableSingleHead(dynamic x) {
  switch (x) {
    case int y || String(length: int y):
      return () => y;
    default:
      return () => 0;
  }
}

joinedVariableMixed(dynamic x) {
  switch (x) {
    case int y || String(length: int y):
    case Object(hashCode: int y):
      return () => y;
    default:
      return () => 0;
  }
}
