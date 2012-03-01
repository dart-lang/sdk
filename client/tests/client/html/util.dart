// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void expectUnsupported(void fn()) =>
  Expect.throws(fn, (e) => e is UnsupportedOperationException);

void expectEmptyRect(ClientRect rect) {
  Expect.equals(0, rect.bottom);
  Expect.equals(0, rect.top);
  Expect.equals(0, rect.left);
  Expect.equals(0, rect.right);
  Expect.equals(0, rect.height);
  Expect.equals(0, rect.width);
}
