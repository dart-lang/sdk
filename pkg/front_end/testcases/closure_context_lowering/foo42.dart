// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:noInline')
int opaqueVal() => int.parse('42');

@pragma('vm:never-inline')
@pragma('wasm:never-inline')
@pragma('dart2js:noInline')
void callClosure(void Function() func) {
  if (opaqueVal() == 1) func();
}

// All of the local variables in [foo42] are expected to be captured: a, b, c,
// d, e, f, g, i, h, j, and k. When the loop-depth allocation strategy is
// enabled, the variables are expected to be split into contexts as follows:
//
// * a, b, c, d;
// * e, f, g;
// * i, h;
// * j, k.
void foo42() {
  int a = opaqueVal();
  int b = opaqueVal();
  int c = opaqueVal();
  int d = opaqueVal();

  callClosure(() {
    print(a);
    print(b);
    print(d);
  });

  callClosure(() {
    print(b);
    print(c);
  });

  while(true) {
    int e = 50;
    int f = 60;
    int g = 70;

    callClosure(() {
      d += 41;
    });

    callClosure(() {
      e += 51;
      f += 61;
    });

    callClosure(() {
      f += 62;
      g += 72;
    });

    print(d);
    print(e);
    print(f);
    print(g);

    if (opaqueVal() == 1) break;
  }

  for (int i = 0; i < 10; ++i) {
    int h = opaqueVal();

    callClosure(() {
      print(h);
      print(i);
    });

    for (int j = 0; j < 10; ++j) {
      int k = 90;

      callClosure(() {
        j += 2;
        k += 91;
      });

      print(k);
    }
  }
}
