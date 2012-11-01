// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class MethodSignatureSyntax {
  a();
  b(x);
  c(int x);
  d(var x);
  e(final x);

  f(x, y);
  g(var x, y);
  h(final x, y);
  j(var x, var y);
  k(final x, final y);

  l(int x, y);
  m(int x, int y);
}
