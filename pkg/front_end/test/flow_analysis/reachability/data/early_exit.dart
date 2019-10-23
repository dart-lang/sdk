// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: beforeSplitStatement:doesNotComplete*/
void beforeSplitStatement(bool b, int i) {
  return;
  /*stmt: unreachable*/ do /*stmt: unreachable*/ {} while (/*unreachable*/ b);
  /*stmt: unreachable*/ for (;;) /*stmt: unreachable*/ {}
  /*stmt: unreachable*/ for (var _
      in /*unreachable*/ []) /*stmt: unreachable*/ {}
  /*stmt: unreachable*/ if (/*unreachable*/ b) /*stmt: unreachable*/ {}
  /*stmt: unreachable*/ switch (/*unreachable*/ i) {
  }
  /*stmt: unreachable*/ try /*stmt: unreachable*/ {} finally /*stmt: unreachable*/ {}
  /*stmt: unreachable*/ while (/*unreachable*/ b) /*stmt: unreachable*/ {}
}
