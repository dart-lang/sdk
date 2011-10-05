// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class FunctionTypeSyntax {
  Function a;
  static Function b;

  Function c() { }
  static Function d() { }

  e(Function f) { }
  static f(Function f) { }

  g(f()) { }
  h(void f()) { }
  j(f(x)) { }
  k(f(x, y)) { }
  l(int f(int x, int y)) { }
  m(int x, int f(x), int y) { }
}
