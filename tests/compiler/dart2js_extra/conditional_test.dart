// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

getZero() { return 0; }

main() {
  int i = getZero();
  int c = i == 0 ? i-- : i++;
  Expect.equals(-1, i);
  Expect.equals(0, c);

  int d = i == 0 ? i-- : i++;
  Expect.equals(0, i);
  Expect.equals(-1, d);

  int e = i == 0 ? --i : ++i;
  Expect.equals(-1, i);
  Expect.equals(-1, e);
}
