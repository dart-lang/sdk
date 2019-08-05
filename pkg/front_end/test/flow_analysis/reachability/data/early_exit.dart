// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: beforeSplitStatement:doesNotComplete*/
void beforeSplitStatement(bool b, int i) {
  return;
  /*stmt: unreachable*/ do {} while (b);
  /*stmt: unreachable*/ for (;;) {}
  /*stmt: unreachable*/ for (var _ in []) {}
  /*stmt: unreachable*/ if (b) {}
  /*stmt: unreachable*/ switch (i) {
  }
  /*stmt: unreachable*/ try {} finally {}
  /*stmt: unreachable*/ while (b) {}
}
