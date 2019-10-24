// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

assignmentDepromotes(Object x) {
  if (x is String) {
    x = 42;
    x;
  }
}

compoundAssignmentDepromotes(Object x) {
  if (x is int) {
    /*int*/ x += 0.5;
    x;
  }
}

nullAwareAssignmentDepromotes(Object x) {
  if (x is int?) {
    x ??= 'foo';
    x;
  }
}

preIncrementDepromotes(Object x) {
  if (x is C) {
    ++ /*C*/ x;
    x;
  }
}

postIncrementDepromotes(Object x) {
  if (x is C) {
    /*C*/ x++;
    x;
  }
}

preDecrementDepromotes(Object x) {
  if (x is C) {
    -- /*C*/ x;
    x;
  }
}

postDecrementDepromotes(Object x) {
  if (x is C) {
    /*C*/ x--;
    x;
  }
}

class C {
  Object operator +(int i) => 'foo';
  Object operator -(int i) => 'foo';
}
