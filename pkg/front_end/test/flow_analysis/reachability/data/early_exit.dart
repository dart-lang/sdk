// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: beforeSplitStatement:doesNotComplete*/
void beforeSplitStatement(bool b, int i) {
  return;
  /*analyzer.stmt: unreachable*/
  /*cfe.unreachable*/
  do /*analyzer.stmt: unreachable*/
      /*cfe.unreachable*/ {} while (/*unreachable*/ b);

  /*analyzer.stmt: unreachable*/
  /*cfe.unreachable*/
  for (;;) /*analyzer.stmt: unreachable*/
  /*cfe.unreachable*/ {}

  /*analyzer.stmt: unreachable*/
  /*cfe.unreachable*/
  /*cfe.iterator: unreachable*/
  /*cfe.current: unreachable*/
  /*cfe.moveNext: unreachable*/
  for (var _ in /*unreachable*/ [])
  /*analyzer.stmt: unreachable*/
  /*cfe.unreachable*/ {}

  /*analyzer.stmt: unreachable*/
  /*cfe.unreachable*/
  if (/*unreachable*/ b)
  /*analyzer.stmt: unreachable*/
  /*cfe.unreachable*/ {}

  /*analyzer.stmt: unreachable*/
  /*cfe.unreachable*/
  switch (/*unreachable*/ i) {
  }

  /*analyzer.stmt: unreachable*/
  /*cfe.unreachable*/
  try /*analyzer.stmt: unreachable*/
  /*cfe.unreachable*/ {} finally
  /*analyzer.stmt: unreachable*/
  /*cfe.unreachable*/ {}

  /*analyzer.stmt: unreachable*/
  /*cfe.unreachable*/
  while (/*unreachable*/ b)
  /*analyzer.stmt: unreachable*/
  /*cfe.unreachable*/ {}
}
