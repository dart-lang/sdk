// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// Check function subtyping of simple function types.

import 'package:expect/expect.dart';

typedef Args0();
typedef Args1(a);
typedef Args2(a, b);
typedef Args3(a, b, c);
typedef Args4(a, b, c, d);
typedef Args5(a, b, c, d, e);
typedef Args6(a, b, c, d, e, f);
typedef Args7(a, b, c, d, e, f, g);
typedef Args8(a, b, c, d, e, f, g, h);
typedef Args9(a, b, c, d, e, f, g, h, i);
typedef Args10(a, b, c, d, e, f, g, h, i, j);
typedef Args11(a, b, c, d, e, f, g, h, i, j, k);
typedef Args12(a, b, c, d, e, f, g, h, i, j, k, l);
typedef Args13(a, b, c, d, e, f, g, h, i, j, k, l, m);
typedef Args14(a, b, c, d, e, f, g, h, i, j, k, l, m, n);
typedef Args15(a, b, c, d, e, f, g, h, i, j, k, l, m, n, o);

void args0() {}
void args1(int a) {}
void args2(int a, int b) {}
void args3(int a, int b, int c) {}
void args4(int a, int b, int c, int d) {}
void args5(int a, int b, int c, int d, int e) {}
void args6(int a, int b, int c, int d, int e, int f) {}
void args7(int a, int b, int c, int d, int e, int f, int g) {}
void args8(int a, int b, int c, int d, int e, int f, int g, int h) {}
void args9(int a, int b, int c, int d, int e, int f, int g, int h, int i) {}
void args10(
    int a, int b, int c, int d, int e, int f, int g, int h, int i, int j) {}
void args11(int a, int b, int c, int d, int e, int f, int g, int h, int i,
    int j, int k) {}
void args12(int a, int b, int c, int d, int e, int f, int g, int h, int i,
    int j, int k, int l) {}
void args13(int a, int b, int c, int d, int e, int f, int g, int h, int i,
    int j, int k, int l, int m) {}
void args14(int a, int b, int c, int d, int e, int f, int g, int h, int i,
    int j, int k, int l, int m, int n) {}
void args15(int a, int b, int c, int d, int e, int f, int g, int h, int i,
    int j, int k, int l, int m, int n, int o) {}

main() {
  Expect.isTrue(args0 is Args0);
  Expect.isFalse(args0 is Args1);
  Expect.isFalse(args0 is Args2);
  Expect.isFalse(args0 is Args3);
  Expect.isFalse(args0 is Args4);
  Expect.isFalse(args0 is Args5);
  Expect.isFalse(args0 is Args6);
  Expect.isFalse(args0 is Args7);
  Expect.isFalse(args0 is Args8);
  Expect.isFalse(args0 is Args9);
  Expect.isFalse(args0 is Args10);
  Expect.isFalse(args0 is Args11);
  Expect.isFalse(args0 is Args12);
  Expect.isFalse(args0 is Args13);
  Expect.isFalse(args0 is Args14);
  Expect.isFalse(args0 is Args15);

  Expect.isFalse(args1 is Args0);
  Expect.isTrue(args1 is Args1);
  Expect.isFalse(args1 is Args2);
  Expect.isFalse(args1 is Args3);
  Expect.isFalse(args1 is Args4);
  Expect.isFalse(args1 is Args5);
  Expect.isFalse(args1 is Args6);
  Expect.isFalse(args1 is Args7);
  Expect.isFalse(args1 is Args8);
  Expect.isFalse(args1 is Args9);
  Expect.isFalse(args1 is Args10);
  Expect.isFalse(args1 is Args11);
  Expect.isFalse(args1 is Args12);
  Expect.isFalse(args1 is Args13);
  Expect.isFalse(args1 is Args14);
  Expect.isFalse(args1 is Args15);

  Expect.isFalse(args2 is Args0);
  Expect.isFalse(args2 is Args1);
  Expect.isTrue(args2 is Args2);
  Expect.isFalse(args2 is Args3);
  Expect.isFalse(args2 is Args4);
  Expect.isFalse(args2 is Args5);
  Expect.isFalse(args2 is Args6);
  Expect.isFalse(args2 is Args7);
  Expect.isFalse(args2 is Args8);
  Expect.isFalse(args2 is Args9);
  Expect.isFalse(args2 is Args10);
  Expect.isFalse(args2 is Args11);
  Expect.isFalse(args2 is Args12);
  Expect.isFalse(args2 is Args13);
  Expect.isFalse(args2 is Args14);
  Expect.isFalse(args2 is Args15);

  Expect.isFalse(args3 is Args0);
  Expect.isFalse(args3 is Args1);
  Expect.isFalse(args3 is Args2);
  Expect.isTrue(args3 is Args3);
  Expect.isFalse(args3 is Args4);
  Expect.isFalse(args3 is Args5);
  Expect.isFalse(args3 is Args6);
  Expect.isFalse(args3 is Args7);
  Expect.isFalse(args3 is Args8);
  Expect.isFalse(args3 is Args9);
  Expect.isFalse(args3 is Args10);
  Expect.isFalse(args3 is Args11);
  Expect.isFalse(args3 is Args12);
  Expect.isFalse(args3 is Args13);
  Expect.isFalse(args3 is Args14);
  Expect.isFalse(args3 is Args15);

  Expect.isFalse(args4 is Args0);
  Expect.isFalse(args4 is Args1);
  Expect.isFalse(args4 is Args2);
  Expect.isFalse(args4 is Args3);
  Expect.isTrue(args4 is Args4);
  Expect.isFalse(args4 is Args5);
  Expect.isFalse(args4 is Args6);
  Expect.isFalse(args4 is Args7);
  Expect.isFalse(args4 is Args8);
  Expect.isFalse(args4 is Args9);
  Expect.isFalse(args4 is Args10);
  Expect.isFalse(args4 is Args11);
  Expect.isFalse(args4 is Args12);
  Expect.isFalse(args4 is Args13);
  Expect.isFalse(args4 is Args14);
  Expect.isFalse(args4 is Args15);

  Expect.isFalse(args5 is Args0);
  Expect.isFalse(args5 is Args1);
  Expect.isFalse(args5 is Args2);
  Expect.isFalse(args5 is Args3);
  Expect.isFalse(args5 is Args4);
  Expect.isTrue(args5 is Args5);
  Expect.isFalse(args5 is Args6);
  Expect.isFalse(args5 is Args7);
  Expect.isFalse(args5 is Args8);
  Expect.isFalse(args5 is Args9);
  Expect.isFalse(args5 is Args10);
  Expect.isFalse(args5 is Args11);
  Expect.isFalse(args5 is Args12);
  Expect.isFalse(args5 is Args13);
  Expect.isFalse(args5 is Args14);
  Expect.isFalse(args5 is Args15);

  Expect.isFalse(args6 is Args0);
  Expect.isFalse(args6 is Args1);
  Expect.isFalse(args6 is Args2);
  Expect.isFalse(args6 is Args3);
  Expect.isFalse(args6 is Args4);
  Expect.isFalse(args6 is Args5);
  Expect.isTrue(args6 is Args6);
  Expect.isFalse(args6 is Args7);
  Expect.isFalse(args6 is Args8);
  Expect.isFalse(args6 is Args9);
  Expect.isFalse(args6 is Args10);
  Expect.isFalse(args6 is Args11);
  Expect.isFalse(args6 is Args12);
  Expect.isFalse(args6 is Args13);
  Expect.isFalse(args6 is Args14);
  Expect.isFalse(args6 is Args15);

  Expect.isFalse(args7 is Args0);
  Expect.isFalse(args7 is Args1);
  Expect.isFalse(args7 is Args2);
  Expect.isFalse(args7 is Args3);
  Expect.isFalse(args7 is Args4);
  Expect.isFalse(args7 is Args5);
  Expect.isFalse(args7 is Args6);
  Expect.isTrue(args7 is Args7);
  Expect.isFalse(args7 is Args8);
  Expect.isFalse(args7 is Args9);
  Expect.isFalse(args7 is Args10);
  Expect.isFalse(args7 is Args11);
  Expect.isFalse(args7 is Args12);
  Expect.isFalse(args7 is Args13);
  Expect.isFalse(args7 is Args14);
  Expect.isFalse(args7 is Args15);

  Expect.isFalse(args8 is Args0);
  Expect.isFalse(args8 is Args1);
  Expect.isFalse(args8 is Args2);
  Expect.isFalse(args8 is Args3);
  Expect.isFalse(args8 is Args4);
  Expect.isFalse(args8 is Args5);
  Expect.isFalse(args8 is Args6);
  Expect.isFalse(args8 is Args7);
  Expect.isTrue(args8 is Args8);
  Expect.isFalse(args8 is Args9);
  Expect.isFalse(args8 is Args10);
  Expect.isFalse(args8 is Args11);
  Expect.isFalse(args8 is Args12);
  Expect.isFalse(args8 is Args13);
  Expect.isFalse(args8 is Args14);
  Expect.isFalse(args8 is Args15);

  Expect.isFalse(args9 is Args0);
  Expect.isFalse(args9 is Args1);
  Expect.isFalse(args9 is Args2);
  Expect.isFalse(args9 is Args3);
  Expect.isFalse(args9 is Args4);
  Expect.isFalse(args9 is Args5);
  Expect.isFalse(args9 is Args6);
  Expect.isFalse(args9 is Args7);
  Expect.isFalse(args9 is Args8);
  Expect.isTrue(args9 is Args9);
  Expect.isFalse(args9 is Args10);
  Expect.isFalse(args9 is Args11);
  Expect.isFalse(args9 is Args12);
  Expect.isFalse(args9 is Args13);
  Expect.isFalse(args9 is Args14);
  Expect.isFalse(args9 is Args15);

  Expect.isFalse(args10 is Args0);
  Expect.isFalse(args10 is Args1);
  Expect.isFalse(args10 is Args2);
  Expect.isFalse(args10 is Args3);
  Expect.isFalse(args10 is Args4);
  Expect.isFalse(args10 is Args5);
  Expect.isFalse(args10 is Args6);
  Expect.isFalse(args10 is Args7);
  Expect.isFalse(args10 is Args8);
  Expect.isFalse(args10 is Args9);
  Expect.isTrue(args10 is Args10);
  Expect.isFalse(args10 is Args11);
  Expect.isFalse(args10 is Args12);
  Expect.isFalse(args10 is Args13);
  Expect.isFalse(args10 is Args14);
  Expect.isFalse(args10 is Args15);

  Expect.isFalse(args11 is Args0);
  Expect.isFalse(args11 is Args1);
  Expect.isFalse(args11 is Args2);
  Expect.isFalse(args11 is Args3);
  Expect.isFalse(args11 is Args4);
  Expect.isFalse(args11 is Args5);
  Expect.isFalse(args11 is Args6);
  Expect.isFalse(args11 is Args7);
  Expect.isFalse(args11 is Args8);
  Expect.isFalse(args11 is Args9);
  Expect.isFalse(args11 is Args10);
  Expect.isTrue(args11 is Args11);
  Expect.isFalse(args11 is Args12);
  Expect.isFalse(args11 is Args13);
  Expect.isFalse(args11 is Args14);
  Expect.isFalse(args11 is Args15);

  Expect.isFalse(args12 is Args0);
  Expect.isFalse(args12 is Args1);
  Expect.isFalse(args12 is Args2);
  Expect.isFalse(args12 is Args3);
  Expect.isFalse(args12 is Args4);
  Expect.isFalse(args12 is Args5);
  Expect.isFalse(args12 is Args6);
  Expect.isFalse(args12 is Args7);
  Expect.isFalse(args12 is Args8);
  Expect.isFalse(args12 is Args9);
  Expect.isFalse(args12 is Args10);
  Expect.isFalse(args12 is Args11);
  Expect.isTrue(args12 is Args12);
  Expect.isFalse(args12 is Args13);
  Expect.isFalse(args12 is Args14);
  Expect.isFalse(args12 is Args15);

  Expect.isFalse(args13 is Args0);
  Expect.isFalse(args13 is Args1);
  Expect.isFalse(args13 is Args2);
  Expect.isFalse(args13 is Args3);
  Expect.isFalse(args13 is Args4);
  Expect.isFalse(args13 is Args5);
  Expect.isFalse(args13 is Args6);
  Expect.isFalse(args13 is Args7);
  Expect.isFalse(args13 is Args8);
  Expect.isFalse(args13 is Args9);
  Expect.isFalse(args13 is Args10);
  Expect.isFalse(args13 is Args11);
  Expect.isFalse(args13 is Args12);
  Expect.isTrue(args13 is Args13);
  Expect.isFalse(args13 is Args14);
  Expect.isFalse(args13 is Args15);

  Expect.isFalse(args14 is Args0);
  Expect.isFalse(args14 is Args1);
  Expect.isFalse(args14 is Args2);
  Expect.isFalse(args14 is Args3);
  Expect.isFalse(args14 is Args4);
  Expect.isFalse(args14 is Args5);
  Expect.isFalse(args14 is Args6);
  Expect.isFalse(args14 is Args7);
  Expect.isFalse(args14 is Args8);
  Expect.isFalse(args14 is Args9);
  Expect.isFalse(args14 is Args10);
  Expect.isFalse(args14 is Args11);
  Expect.isFalse(args14 is Args12);
  Expect.isFalse(args14 is Args13);
  Expect.isTrue(args14 is Args14);
  Expect.isFalse(args14 is Args15);

  Expect.isFalse(args15 is Args0);
  Expect.isFalse(args15 is Args1);
  Expect.isFalse(args15 is Args2);
  Expect.isFalse(args15 is Args3);
  Expect.isFalse(args15 is Args4);
  Expect.isFalse(args15 is Args5);
  Expect.isFalse(args15 is Args6);
  Expect.isFalse(args15 is Args7);
  Expect.isFalse(args15 is Args8);
  Expect.isFalse(args15 is Args9);
  Expect.isFalse(args15 is Args10);
  Expect.isFalse(args15 is Args11);
  Expect.isFalse(args15 is Args12);
  Expect.isFalse(args15 is Args13);
  Expect.isFalse(args15 is Args14);
  Expect.isTrue(args15 is Args15);
}
